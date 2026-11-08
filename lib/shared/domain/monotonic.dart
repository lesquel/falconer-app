/// Monotonic time for security windows (lock timeout, re-verification): it
/// never goes back when the user changes the wall clock.
library;

/// Time elapsed since an arbitrary fixed start.
typedef Elapsed = Duration Function();

/// A monotonic [Elapsed] backed by a running [Stopwatch].
Elapsed monotonicClock() {
  final w = Stopwatch()..start();
  return () => w.elapsed;
}
