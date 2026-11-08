/// One TCP round trip to the host's one-shot pairing listener.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../shared/domain/failure.dart';
import '../models/pair_crypto.dart';

class PairSocket {
  /// The host asks its user to confirm the pairing (y/N) before replying,
  /// so the deadline leaves time for that.
  const PairSocket({this.deadline = const Duration(seconds: 120)});

  /// One budget for connect + write + read of the whole reply line, so a host
  /// that trickles bytes cannot hold the exchange open.
  final Duration deadline;

  Future<String> roundTrip(String ip, int port, String line) async {
    final sw = Stopwatch()..start();
    Duration left() {
      final rest = deadline - sw.elapsed;
      return rest.isNegative ? Duration.zero : rest;
    }

    final Socket socket;
    try {
      socket = await Socket.connect(ip, port, timeout: left());
    } on SocketException {
      throw const PairingFailure(
        'Could not reach the host. Check that Tailscale is on and openmosh-hook pair is still running.',
      );
    }
    try {
      return await _exchange(socket, line).timeout(left());
    } on TimeoutException {
      throw const PairingFailure('The host did not answer in time.');
    } on SocketException {
      throw const PairingFailure('The pairing connection failed.');
    } finally {
      socket.destroy();
    }
  }

  static Future<String> _exchange(Socket socket, String line) async {
    socket.add(utf8.encode('$line\n'));
    await socket.flush();
    final buf = <int>[];
    await for (final chunk in socket) {
      for (final b in chunk) {
        if (b == 0x0a) return _decode(buf);
        buf.add(b);
        if (buf.length > maxPairLineBytes) {
          throw const PairingFailure('Pairing reply is too large.');
        }
      }
    }
    throw const PairingFailure('The host closed the connection.');
  }

  static String _decode(List<int> line) {
    try {
      return utf8.decode(line);
    } on FormatException {
      throw const PairingFailure('Unexpected pairing reply.');
    }
  }
}
