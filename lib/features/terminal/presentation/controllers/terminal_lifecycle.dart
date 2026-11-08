/// What terminals do while the app is in the background: no reconnect
/// retries, and after [closeInBackgroundAfter] every shell and SSH
/// connection is closed. Pushes do not depend on SSH.
library;

import 'dart:async';

import 'terminal_session.dart';
import 'terminal_session_pool.dart';

/// Background time after which pooled shells and SSH connections close.
const closeInBackgroundAfter = Duration(minutes: 10);

typedef TimerFactory = Timer Function(Duration, void Function());

final class TerminalLifecycle {
  TerminalLifecycle({
    required this.pool,
    required this.disconnectAll,
    this.closeAfter = closeInBackgroundAfter,
    TimerFactory? timer,
  }) : _timer = timer ?? Timer.new;

  final TerminalSessionPool<TerminalSession> pool;

  /// Closes every SSH connection (`HostConnections.disconnectAll`).
  final Future<void> Function() disconnectAll;
  final Duration closeAfter;
  final TimerFactory _timer;
  Timer? _closing;
  bool _background = false;

  bool get inBackground => _background;

  /// The app went to the background.
  void paused() {
    _background = true;
    for (final s in pool.sessions) {
      s.runner.paused = true;
    }
    _closing ??= _timer(closeAfter, () => unawaited(_closeAll()));
  }

  /// The app is back. Retries start again at once; a terminal still on
  /// screen that was suspended reconnects from its screen, after the
  /// user is verified.
  void resumed() {
    _background = false;
    _closing?.cancel();
    _closing = null;
    for (final s in pool.sessions) {
      s.runner.paused = false;
    }
  }

  Future<void> _closeAll() async {
    _closing = null;
    if (!_background) return;
    await pool.releaseHidden();
    for (final s in pool.shownSessions) {
      await s.runner.suspend();
    }
    await disconnectAll();
  }
}
