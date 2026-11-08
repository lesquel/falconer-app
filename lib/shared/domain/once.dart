/// Wraps [load] so it runs at most once; later calls share its future.
Future<T> Function() once<T>(Future<T> Function() load) {
  Future<T>? result;
  return () => result ??= load();
}
