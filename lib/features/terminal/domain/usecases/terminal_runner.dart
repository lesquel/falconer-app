/// Keeps one terminal view attached to a host: connect, open a PTY shell,
/// re-attach the Herdr/tmux session, and reconnect with backoff when the
/// connection drops (TRD §4.4). A shell that exits on a live connection
/// ends the session; security failures end it without retry.
library;

import 'dart:async';
import 'dart:convert';

import '../../../../shared/domain/failure.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../../shared/ssh/domain/ssh_ports.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../entities/backoff_policy.dart';
import '../repositories/terminal_emulator.dart';

enum TerminalPhase { idle, connecting, connected, reconnecting, closed, failed }

typedef Sleep = Future<void> Function(Duration);

/// Quiet time before a terminal size reaches the SSH channel. A pinch or
/// a keyboard animation resizes every frame; the server (and the TUI
/// redrawing on SIGWINCH) only needs the final size.
const resizeDebounce = Duration(milliseconds: 150);

final class TerminalRunner {
  TerminalRunner({
    required this.hostId,
    required this.connections,
    required this.emulator,
    this.attachCommand,
    BackoffPolicy? backoff,
    Sleep? sleep,
    this.attachFallback = const Duration(milliseconds: 1500),
  }) : _backoff = backoff ?? BackoffPolicy(),
       _sleep = sleep ?? ((d) => Future<void>.delayed(d));

  final String hostId;
  final HostConnections connections;
  final TerminalEmulator emulator;
  final String? attachCommand;

  /// How long to wait for the shell to print (its prompt) before typing the
  /// attach command anyway. Typing before the prompt can be swallowed by a
  /// login shell, which left a reconnect in a plain shell.
  final Duration attachFallback;
  final BackoffPolicy _backoff;
  final Sleep _sleep;

  Timer? _resizeTimer;
  (int, int)? _pendingSize;
  final _phases = StreamController<TerminalPhase>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];
  TerminalPhase _phase = TerminalPhase.idle;
  AppFailure? failure;
  ShellChannel? _shell;
  SshConnection? _conn;
  Completer<void>? _wake;
  bool _disposed = false;
  bool _running = false;
  bool _paused = false;
  bool _suspended = false;

  /// The next connection starts from a clean screen.
  bool _resetOnConnect = false;

  TerminalPhase get phase => _phase;
  Stream<TerminalPhase> get phases => _phases.stream;

  /// App in the background: a dropped or failed connection waits for
  /// [wake] (network regained) or for the app to resume instead of retrying
  /// on a timer. Resuming retries at once.
  bool get paused => _paused;
  set paused(bool value) {
    if (_paused == value) return;
    _paused = value;
    if (!value) _completeWake();
  }

  /// Stopped by [suspend]; only `wake(restart: true)` starts it again.
  bool get suspended => _suspended;

  void _set(TerminalPhase p) {
    _phase = p;
    if (!_phases.isClosed) _phases.add(p);
  }

  Future<void> start() async {
    if (_running || _disposed) return;
    _running = true;
    _suspended = false;
    if (_subs.isEmpty) {
      _subs.add(emulator.input.listen((s) => send(s)));
      _subs.add(emulator.resizes.listen(_queueResize));
    }
    var attempt = 0;
    var reconnect = _resetOnConnect;
    _resetOnConnect = false;
    failure = null;
    while (!_disposed && !_suspended) {
      _set(attempt == 0 ? TerminalPhase.connecting : TerminalPhase.reconnecting);
      try {
        final conn = await connections.connection(hostId);
        final shell = await conn.openShell(cols: emulator.cols, rows: emulator.rows);
        if (_disposed || _suspended) {
          await shell.close();
          break;
        }
        _conn = conn;
        _shell = shell;
        attempt = 0;
        // A reconnect starts from a clean screen: the dropped session left
        // its alternate screen and mouse modes behind.
        if (reconnect) emulator.reset();
        reconnect = true;
        _set(TerminalPhase.connected);
        final attach = attachCommand;
        var attached = attach == null;
        Timer? fallback;
        void sendAttach() {
          if (attached) return;
          attached = true;
          fallback?.cancel();
          unawaited(shell.write(utf8.encode('$attach\r')).catchError((Object _) {}));
        }

        if (!attached) fallback = Timer(attachFallback, sendAttach);
        try {
          await for (final chunk in shell.output) {
            emulator.feed(chunk);
            sendAttach();
          }
        } finally {
          fallback?.cancel();
        }
        _shell = null;
        if (_disposed || _suspended) break;
        if (!conn.isClosed) {
          emulator.notice('[session ended]');
          _set(TerminalPhase.closed);
          break;
        }
        final why = conn.closeReason;
        Log.warning('ssh', 'connection lost: ${why ?? 'unknown'}');
        emulator.notice(
          why == null
              ? '[connection lost, reconnecting…]'
              : '[connection lost: $why — reconnecting…]',
        );
      } on HostKeyMismatchFailure catch (e) {
        _fail(e);
        break;
      } on UserCancelledFailure catch (e) {
        _fail(e);
        break;
      } on AuthFailure catch (e) {
        _fail(e);
        break;
      } on AppFailure catch (e) {
        failure = e;
        emulator.notice('[${e.message} Retrying…]');
      }
      if (_disposed || _suspended) break;
      _set(TerminalPhase.reconnecting);
      final wake = _wake = Completer<void>();
      if (!_paused) await Future.any([_sleep(_backoff.delay(attempt)), wake.future]);
      // Paused (now or while sleeping): no retry until resume or network.
      if (_paused && !wake.isCompleted) await wake.future;
      _wake = null;
      attempt++;
    }
    _running = false;
    if (_suspended && !_disposed) _set(TerminalPhase.idle);
  }

  void _queueResize((int, int) size) {
    _pendingSize = size;
    _resizeTimer?.cancel();
    _resizeTimer = Timer(resizeDebounce, () {
      final s = _pendingSize;
      _pendingSize = null;
      // Without a shell the next one opens at the emulator's current size.
      if (s != null) _shell?.resize(s.$1, s.$2).catchError((Object _) {});
    });
  }

  void _completeWake() {
    final w = _wake;
    if (w != null && !w.isCompleted) w.complete();
  }

  /// Closes the shell and stops without retrying (the app stayed long in
  /// the background). The screen is kept until `wake(restart: true)`
  /// reconnects, which clears it before re-attaching.
  Future<void> suspend() async {
    if (_disposed) return;
    _suspended = true;
    _resetOnConnect = true;
    _completeWake();
    final shell = _shell;
    _shell = null;
    await shell?.close();
    if (!_running) _set(TerminalPhase.idle);
  }

  void _fail(AppFailure e) {
    failure = e;
    _shell = null;
    _set(TerminalPhase.failed);
  }

  /// Network came back or the app resumed: retry now instead of waiting,
  /// or restart after a clean end/failure or a [suspend] if [restart] is set.
  void wake({bool restart = false}) {
    _completeWake();
    if (_suspended && !restart) return;
    if (_conn?.isClosed ?? false) _shell?.close();
    if (restart && !_running) unawaited(start());
  }

  Future<void> send(String data) async {
    final s = _shell;
    if (s == null || data.isEmpty) return;
    try {
      await s.write(utf8.encode(data));
    } on AppFailure {
      // the read loop notices the drop and reconnects
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _resizeTimer?.cancel();
    _completeWake();
    for (final s in _subs) {
      await s.cancel();
    }
    await _shell?.close();
    await _phases.close();
  }
}
