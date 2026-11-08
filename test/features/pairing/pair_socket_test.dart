import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/pairing/data/datasources/pair_socket.dart';
import 'package:openmosh/shared/domain/failure.dart';

void main() {
  late ServerSocket server;
  final timers = <Timer>[];

  setUp(() async => server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
  tearDown(() async {
    for (final t in timers) {
      t.cancel();
    }
    await server.close();
  });

  test('a host trickling bytes is cut off by one overall deadline', () async {
    server.listen((s) {
      timers.add(Timer.periodic(const Duration(milliseconds: 50), (_) => s.add([0x41])));
    });
    const socket = PairSocket(deadline: Duration(milliseconds: 400));
    final sw = Stopwatch()..start();
    await expectLater(
      socket.roundTrip('127.0.0.1', server.port, 'hi'),
      throwsA(
        isA<PairingFailure>().having((e) => e.message, 'message', contains('did not answer')),
      ),
    );
    expect(sw.elapsed, lessThan(const Duration(seconds: 2)));
  });

  test('a reply line within the deadline is returned', () async {
    server.listen((s) {
      s.listen((_) {
        s.add(utf8.encode('{"v":1}\n'));
      });
    });
    const socket = PairSocket(deadline: Duration(seconds: 5));
    expect(await socket.roundTrip('127.0.0.1', server.port, 'hi'), '{"v":1}');
  });

  test('an oversized reply is refused', () async {
    server.listen((s) => s.add(List<int>.filled(17 * 1024, 0x41)));
    const socket = PairSocket(deadline: Duration(seconds: 5));
    await expectLater(
      socket.roundTrip('127.0.0.1', server.port, 'hi'),
      throwsA(isA<PairingFailure>().having((e) => e.message, 'message', contains('too large'))),
    );
  });

  test('a reply that is not UTF-8 is a pairing failure', () async {
    server.listen((s) {
      s.listen((_) => s.add([0xff, 0xfe, 0x0a]));
    });
    const socket = PairSocket(deadline: Duration(seconds: 2));
    await expectLater(
      socket.roundTrip('127.0.0.1', server.port, 'hi'),
      throwsA(isA<PairingFailure>()),
    );
  });
}
