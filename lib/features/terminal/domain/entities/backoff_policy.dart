/// Reconnect delays: 0.5 s doubling to 8 s, shortened by up to 20 % jitter
/// so several tabs do not reconnect in lockstep.
library;

import 'dart:math';

final class BackoffPolicy {
  BackoffPolicy({double Function()? random}) : _random = random ?? Random().nextDouble;

  static const initial = Duration(milliseconds: 500);
  static const max = Duration(seconds: 8);
  static const jitter = 0.2;

  final double Function() _random;

  Duration delay(int attempt) {
    final n = attempt < 0 ? 0 : (attempt > 10 ? 10 : attempt);
    final base = min(initial.inMilliseconds * (1 << n), max.inMilliseconds);
    final ms = base - (base * jitter * _random()).floor();
    return Duration(milliseconds: ms);
  }
}
