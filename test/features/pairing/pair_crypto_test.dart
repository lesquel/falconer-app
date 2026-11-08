import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/pairing/data/models/pair_crypto.dart';
import 'package:openmosh/shared/crypto/openmosh_crypto.dart' as c;
import 'package:openmosh/shared/domain/b64u.dart';
import 'package:openmosh/shared/domain/failure.dart';

import '../../support/vectors.dart';

void main() {
  final v = loadVector('pair_v1.json');
  final skip = v == null ? vectorsPending : false;

  test('request line matches the shared vector', () async {
    final eph = await c.x25519FromPrivate(b64uDecode(v!['eph_priv']! as String));
    final req = await PairCrypto.sealRequest(
      hostPublicKey: b64uDecode(v['host_pub']! as String),
      token: b64uDecode(v['token']! as String),
      plaintext: textOrBytes(v['req_plaintext']! as String, b64uDecode),
      ephemeral: eph,
      nonce: b64uDecode(v['nonce_req']! as String),
    );
    expect(jsonDecode(req.line), jsonDecode(v['req_line']! as String));
    expect(b64uEncode(await req.responseKey.extractBytes()), v['k_resp']);
  }, skip: skip);

  test('response line decrypts to device id, alias and SSH details', () async {
    final eph = await c.x25519FromPrivate(b64uDecode(v!['eph_priv']! as String));
    final req = await PairCrypto.sealRequest(
      hostPublicKey: b64uDecode(v['host_pub']! as String),
      token: b64uDecode(v['token']! as String),
      plaintext: textOrBytes(v['req_plaintext']! as String, b64uDecode),
      ephemeral: eph,
      nonce: b64uDecode(v['nonce_req']! as String),
    );
    final resp = await PairCrypto.openResponse(v['resp_line']! as String, req.responseKey);
    final expected = jsonDecode(v['resp_plaintext']! as String) as Map<String, Object?>;
    expect(resp.deviceId, expected['device_id']);
    expect(resp.alias, expected['alias']);
    expect(resp.sshUser, expected['ssh_user']);
    expect(resp.sshPort, expected['ssh_port']);
    expect(resp.sshFingerprint, expected['ssh_fp']);
  }, skip: skip);

  group('without vectors', () {
    test('request plaintext carries exactly the contract fields', () {
      final body = PairRequestBody(
        token: List<int>.filled(32, 1),
        name: 'Phone',
        sshPublicKey: 'ssh-ed25519 AAAA x',
        pushPublicKey: List<int>.filled(32, 2),
        endpoint: 'https://ntfy.sh/up1',
      );
      final json = jsonDecode(utf8.decode(body.toJsonBytes())) as Map<String, Object?>;
      expect(json.keys.toSet(), {'tok', 'name', 'ssh_pub', 'ppk', 'endpoint'});
      expect(json['tok'], b64uEncode(List<int>.filled(32, 1)));
      expect(json['ppk'], b64uEncode(List<int>.filled(32, 2)));
    });

    test('a request line round-trips with the host side derivation', () async {
      final host = await c.newX25519KeyPair();
      final hostPub = await c.x25519PublicBytes(host);
      final tok = c.randomBytes(32);
      final req = await PairCrypto.sealRequest(
        hostPublicKey: hostPub,
        token: tok,
        plaintext: utf8.encode('{"a":1}'),
      );
      expect(req.line.endsWith('\n'), isFalse);
      final line = jsonDecode(req.line) as Map<String, Object?>;
      expect(line['v'], 1);
      final kReq = await c.deriveKey(
        private: host,
        remotePublic: b64uDecode(line['e']! as String),
        salt: tok,
        info: 'openmosh/pair/v1/req',
      );
      final pt = await c.open(
        key: kReq,
        nonce: b64uDecode(line['n']! as String),
        combined: b64uDecode(line['c']! as String),
        aad: 'openmosh/pair/v1',
      );
      expect(utf8.decode(pt), '{"a":1}');
    });

    test('rejection and tampering surface as PairingFailure', () async {
      final key = await c.deriveKey(
        private: await c.newX25519KeyPair(),
        remotePublic: await c.x25519PublicBytes(await c.newX25519KeyPair()),
        salt: [1],
        info: 'x',
      );
      expect(
        PairCrypto.openResponse('{"v":1,"err":"pair_rejected"}', key),
        throwsA(isA<PairingFailure>()),
      );
      expect(
        PairCrypto.openResponse('{"v":1,"n":"${b64uEncode(List.filled(24, 0))}","c":"AAAA"}', key),
        throwsA(isA<PairingFailure>()),
      );
      expect(PairCrypto.openResponse('garbage', key), throwsA(isA<PairingFailure>()));
    });

    Future<PairResponse> replyWith(Map<String, Object?> fields) async {
      final body = {
        'ssh_user': 'me',
        'ssh_port': 22,
        'ssh_fp': 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM',
        ...fields,
      };
      final host = await c.newX25519KeyPair();
      final req = await PairCrypto.sealRequest(
        hostPublicKey: await c.x25519PublicBytes(host),
        token: c.randomBytes(16),
        plaintext: utf8.encode('{}'),
      );
      final n = c.randomBytes(c.nonceLength);
      final ct = await c.seal(
        key: req.responseKey,
        nonce: n,
        plaintext: utf8.encode(jsonEncode(body)),
        aad: 'openmosh/pair/v1',
      );
      final line = jsonEncode({'v': 1, 'n': b64uEncode(n), 'c': b64uEncode(ct)});
      return PairCrypto.openResponse(line, req.responseKey);
    }

    test('reply alias is stripped of control, format and separator characters', () async {
      final r = await replyWith({
        'device_id': 'd1',
        'alias': '\u202Ework\u200Bstation\uFEFF\u2028\u0007\u2066',
      });
      expect(r.alias, 'workstation');
      expect(r.deviceId, 'd1');
    });

    test('a plain reply alias is kept as is', () async {
      final r = await replyWith({'device_id': 'd1', 'alias': 'My Box_2'});
      expect(r.alias, 'My Box_2');
    });

    test('reply SSH details must be well formed', () async {
      for (final bad in <Map<String, Object?>>[
        {'ssh_fp': 'MD5:aa'},
        {'ssh_fp': 'SHA256:short'},
        {'ssh_user': 'me; rm -rf'},
        {'ssh_user': ''},
        {'ssh_port': 0},
        {'ssh_port': 65536},
        {'ssh_port': '22'},
        {'ssh_fp': null},
      ]) {
        await expectLater(
          replyWith({'device_id': 'd1', 'alias': 'box', ...bad}),
          throwsA(isA<PairingFailure>()),
          reason: '$bad',
        );
      }
    });

    test('a reply alias longer than 64 characters is invalid', () async {
      await expectLater(
        replyWith({'device_id': 'd1', 'alias': 'a' * 65}),
        throwsA(isA<PairingFailure>()),
      );
    });
  });
}
