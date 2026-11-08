/// Time for security windows (app lock timeout, re-verification).
///
/// On Android it is `SystemClock.elapsedRealtime()`: it keeps counting while
/// the phone sleeps and cannot be moved by changing the wall clock. A Dart
/// [Stopwatch] stops during deep sleep, which would stretch the windows.
library;

import 'package:flutter/services.dart';

/// Time elapsed since an arbitrary fixed start.
typedef Elapsed = Future<Duration> Function();

const _channel = MethodChannel('dev.openmosh/clock');

/// The boot clock, or a [Stopwatch] where the platform channel is missing
/// (tests, desktop).
Elapsed bootClock() {
  final w = Stopwatch()..start();
  var native = true;
  return () async {
    if (native) {
      try {
        final ms = await _channel.invokeMethod<int>('elapsedRealtime');
        if (ms != null) return Duration(milliseconds: ms);
      } on MissingPluginException {
        native = false;
      } on PlatformException {
        native = false;
      }
    }
    return w.elapsed;
  };
}
