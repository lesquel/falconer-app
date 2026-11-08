/// One TCP round trip to the host's one-shot pairing listener.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../shared/domain/failure.dart';
import '../models/pair_crypto.dart';

class PairSocket {
  const PairSocket({this.connectTimeout = const Duration(seconds: 10), this.replyTimeout = const Duration(seconds: 20)});

  final Duration connectTimeout;
  final Duration replyTimeout;

  Future<String> roundTrip(String ip, int port, String line) async {
    final Socket socket;
    try {
      socket = await Socket.connect(ip, port, timeout: connectTimeout);
    } on SocketException {
      throw const PairingFailure(
          'Could not reach the host. Check that Tailscale is on and openmosh-hook pair is still running.');
    }
    try {
      socket.add(utf8.encode('$line\n'));
      await socket.flush();
      final buf = <int>[];
      await for (final chunk in socket.timeout(replyTimeout)) {
        for (final b in chunk) {
          if (b == 0x0a) return utf8.decode(buf);
          buf.add(b);
          if (buf.length > maxPairLineBytes) throw const PairingFailure('Pairing reply is too large.');
        }
      }
      throw const PairingFailure('The host closed the connection.');
    } on TimeoutException {
      throw const PairingFailure('The host did not answer in time.');
    } on SocketException {
      throw const PairingFailure('The pairing connection failed.');
    } finally {
      socket.destroy();
    }
  }
}
