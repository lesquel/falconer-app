/// Push payload decryption (TRD §6.5), pure Dart for the background isolate.
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../../../shared/crypto/openmosh_crypto.dart' as c;
import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/failure.dart';

const _aad = 'openmosh/push/v1';
const maxPushBodyBytes = 3 * 1024;

abstract final class PushCrypto {
  static const _invalid = PushFailure('Discarded an invalid push message.');

  /// Routing id (`kid` = device_id) so the caller can pick the host keys.
  static String? kidOf(List<int> body) {
    final m = _decode(body);
    final kid = m?['kid'];
    return kid is String ? kid : null;
  }

  static Future<SecretKey> deriveKey({
    required List<int> devicePrivate,
    required List<int> hostPublicKey,
    required String deviceId,
  }) async {
    final pair = await c.x25519FromPrivate(devicePrivate);
    return c.deriveKey(
      private: pair,
      remotePublic: hostPublicKey,
      salt: const [],
      info: 'openmosh/push/v1/$deviceId',
    );
  }

  static Future<Map<String, Object?>> open({
    required List<int> body,
    required List<int> devicePrivate,
    required List<int> hostPublicKey,
    required String deviceId,
  }) async {
    if (body.length > maxPushBodyBytes + 1024) throw _invalid;
    final m = _decode(body);
    if (m == null || m['v'] != 1 || m['kid'] != deviceId) throw _invalid;
    final n = m['n'];
    final ct = m['c'];
    if (n is! String || ct is! String) throw _invalid;
    try {
      final key = await deriveKey(
          devicePrivate: devicePrivate, hostPublicKey: hostPublicKey, deviceId: deviceId);
      final pt = await c.open(key: key, nonce: b64uDecode(n), combined: b64uDecode(ct), aad: _aad);
      final out = jsonDecode(utf8.decode(pt));
      if (out is! Map<String, Object?>) throw _invalid;
      return out;
    } on FormatException {
      throw _invalid;
    } on SecretBoxAuthenticationError {
      throw _invalid;
    } on ArgumentError {
      throw _invalid;
    }
  }

  static Map<String, Object?>? _decode(List<int> body) {
    try {
      final m = jsonDecode(utf8.decode(body));
      return m is Map<String, Object?> ? m : null;
    } on FormatException {
      return null;
    }
  }
}
