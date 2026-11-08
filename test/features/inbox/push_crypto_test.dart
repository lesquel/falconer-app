import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/models/push_crypto.dart';
import 'package:openmosh/shared/crypto/openmosh_crypto.dart' as c;
import 'package:openmosh/shared/domain/b64u.dart';
import 'package:openmosh/shared/domain/failure.dart';

import '../../support/vectors.dart';

void main() {
  final v = loadVector('push_v1.json');
  final skip = v == null ? vectorsPending : false;

  Future<Map<String, Object?>> openVector(String body, {String? deviceId}) async =>
      PushCrypto.open(
        body: utf8.encode(body),
        devicePrivate: b64uDecode(v!['device_priv']! as String),
        hostPublicKey: b64uDecode(v['host_pub']! as String),
        deviceId: deviceId ?? v['device_id']! as String,
      );

  test('derived key matches the shared vector', () async {
    final key = await PushCrypto.deriveKey(
      devicePrivate: b64uDecode(v!['device_priv']! as String),
      hostPublicKey: b64uDecode(v['host_pub']! as String),
      deviceId: v['device_id']! as String,
    );
    expect(b64uEncode(await key.extractBytes()), v['key']);
  }, skip: skip);

  test('body decrypts to the vector plaintext', () async {
    final out = await openVector(v!['body']! as String);
    expect(out, jsonDecode(v['plaintext']! as String));
  }, skip: skip);

  test('tampered ciphertext is rejected', () async {
    final body = jsonDecode(v!['body']! as String) as Map<String, Object?>;
    final ct = b64uDecode(body['c']! as String);
    ct[0] ^= 0x01;
    body['c'] = b64uEncode(ct);
    expect(openVector(jsonEncode(body)), throwsA(isA<PushFailure>()));
  }, skip: skip);

  test('wrong kid is rejected before decrypting', () async {
    expect(openVector(v!['body']! as String, deviceId: 'someone-else'),
        throwsA(isA<PushFailure>()));
  }, skip: skip);

  group('without vectors', () {
    late Map<String, Object?> body;
    late List<int> devPriv;
    late List<int> hostPub;
    const id = 'AwMDAwMDAwMDAwMDAwMDAw';

    setUp(() async {
      final host = await c.newX25519KeyPair();
      final dev = await c.newX25519KeyPair();
      devPriv = await c.x25519PrivateBytes(dev);
      hostPub = await c.x25519PublicBytes(host);
      final key = await c.deriveKey(
        private: host,
        remotePublic: await c.x25519PublicBytes(dev),
        salt: const [],
        info: 'openmosh/push/v1/$id',
      );
      final n = c.randomBytes(24);
      final ct = await c.seal(key: key, nonce: n, plaintext: utf8.encode('{"id":"e"}'), aad: 'openmosh/push/v1');
      body = {'v': 1, 'kid': id, 'n': b64uEncode(n), 'c': b64uEncode(ct)};
    });

    Future<Map<String, Object?>> openBody(Map<String, Object?> b) => PushCrypto.open(
        body: utf8.encode(jsonEncode(b)), devicePrivate: devPriv, hostPublicKey: hostPub, deviceId: id);

    test('round trip with host-side sealing', () async {
      expect(await openBody(body), {'id': 'e'});
    });

    test('wrong aad, version or nonce is rejected', () async {
      expect(openBody({...body, 'v': 2}), throwsA(isA<PushFailure>()));
      expect(openBody({...body, 'n': b64uEncode(List.filled(24, 0))}), throwsA(isA<PushFailure>()));
      expect(openBody({...body, 'kid': 'x'}), throwsA(isA<PushFailure>()));
      expect(PushCrypto.open(body: utf8.encode('nope'), devicePrivate: devPriv, hostPublicKey: hostPub, deviceId: id),
          throwsA(isA<PushFailure>()));
    });

    test('kidOf reads the routing id without decrypting', () {
      expect(PushCrypto.kidOf(utf8.encode(jsonEncode(body))), id);
      expect(PushCrypto.kidOf(utf8.encode('[]')), isNull);
    });
  });
}
