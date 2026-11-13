import Foundation

#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

/// `dev.openmosh/clock`: a monotonic clock for the app lock and re-verification
/// windows. It keeps counting while the device sleeps and ignores wall-clock
/// changes, like Android's `SystemClock.elapsedRealtime()`.
///
/// `CLOCK_MONOTONIC_RAW` is the clock that includes sleep time; the man page of
/// `clock_gettime(3)` documents `CLOCK_UPTIME_RAW` (and so
/// `mach_absolute_time()` and `ProcessInfo.systemUptime`) as the variant that
/// "does not increment while the system is asleep", so those must not be used.
enum BootClock {
  static func elapsedRealtimeMillis() -> Int64 {
    Int64(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) / 1_000_000)
  }

  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "dev.openmosh/clock", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        if call.method == "elapsedRealtime" {
          result(elapsedRealtimeMillis())
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
  }
}
