/// Real time for the Herdr screens without a daemon: one call at a time to
/// `herdr snapshot|read --since <rev> --wait-ms N`, which the hook answers
/// when the state changes or at the deadline; then the next call.
library;

import 'dart:async';

import '../../../../shared/domain/failure.dart';
import '../../../terminal/domain/entities/backoff_policy.dart';
import '../../domain/entities/herdr_snapshot.dart';

/// How long the hook may hold one call (under the 30 s exec timeout).
const herdrLongPollMs = 15000;

/// Errors only the user can fix: polling stops until [LongPoller.start].
bool stopsPolling(Object e) =>
    e is UserCancelledFailure ||
    e is AuthFailure ||
    e is HostKeyMismatchFailure ||
    e is ValidationFailure ||
    (e is HookFailure &&
        const {'hook_missing', 'hook_outdated', 'invalid_request'}.contains(e.code));

final class LongPoller<T> {
  LongPoller({
    required this.fetch,
    required this.onData,
    required this.onError,
    Duration Function(int attempt)? backoff,
  }) : _backoff = backoff ?? BackoffPolicy().delay;

  /// One call with the last known revision (null on the first call).
  final Future<Polled<T>> Function(String? since) fetch;
  final void Function(T body, String rev) onData;
  final void Function(Object error) onError;
  final Duration Function(int attempt) _backoff;

  String? _rev;
  bool _running = false;
  bool _looping = false;
  bool _disposed = false;
  int _failures = 0;
  Completer<void>? _wake;

  bool get running => _running;

  /// Starts or resumes polling. Never runs two calls at once: when a call is
  /// still in flight, the loop that owns it simply keeps going.
  void start() {
    if (_disposed) return;
    _running = true;
    if (!_looping) unawaited(_loop());
  }

  /// Stops after the call in flight (the screen is hidden).
  void pause() {
    _running = false;
    _interrupt();
  }

  /// Polls again now instead of waiting out a backoff (after an action; a
  /// call already in flight returns by itself once the state changes).
  void poke() {
    _failures = 0;
    _interrupt();
  }

  void dispose() {
    _disposed = true;
    pause();
  }

  void _interrupt() {
    final w = _wake;
    if (w != null && !w.isCompleted) w.complete();
  }

  Future<void> _loop() async {
    _looping = true;
    try {
      while (_running && !_disposed) {
        try {
          final r = await fetch(_rev);
          if (_disposed) return;
          _failures = 0;
          _rev = r.rev;
          final body = r.body;
          if (!r.unchanged && body != null) onData(body, r.rev);
        } catch (e) {
          if (_disposed) return;
          onError(e);
          if (stopsPolling(e)) {
            _running = false;
            return;
          }
          if (_running) await _sleep(_backoff(_failures++));
        }
      }
    } finally {
      _looping = false;
    }
  }

  Future<void> _sleep(Duration d) {
    final c = _wake = Completer<void>();
    final t = Timer(d, () {
      if (!c.isCompleted) c.complete();
    });
    return c.future.whenComplete(t.cancel);
  }
}
