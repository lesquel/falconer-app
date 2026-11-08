import 'package:connectivity_plus/connectivity_plus.dart';

/// Emits when the device regains a network connection.
Stream<void> networkRegained([Connectivity? c]) => (c ?? Connectivity())
    .onConnectivityChanged
    .map((r) => r.any((x) => x != ConnectivityResult.none))
    .distinct()
    .where((online) => online)
    .map((_) {});
