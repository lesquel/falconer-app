import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/pairing/domain/entities/pair_payload.dart';
import 'package:openmosh/shared/domain/b64u.dart';

String link(Map<String, Object?> json) =>
    'openmosh://pair?d=${b64uEncode(utf8.encode(jsonEncode(json)))}';

Map<String, Object?> valid() => {
  'v': 1,
  'alias': 'workstation',
  'addr': 'workstation.tail1234.ts.net',
  'ip': '100.101.102.103',
  'ssh_port': 22,
  'ssh_user': 'me',
  'ssh_fp': 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM',
  'hpk': b64uEncode(List<int>.filled(32, 7)),
  'port': 40123,
  'tok': b64uEncode(List<int>.filled(32, 9)),
  'exp': 1000,
};

final now = DateTime.fromMillisecondsSinceEpoch(900 * 1000, isUtc: true);

PairCodeError? errorOf(String raw, {DateTime? at}) {
  try {
    PairPayload.parse(raw, now: at ?? now);
    return null;
  } on PairCodeFailure catch (e) {
    return e.reason;
  }
}

void main() {
  test('parses a valid code', () {
    final p = PairPayload.parse(link(valid()), now: now);
    expect(p.alias, 'workstation');
    expect(p.ip, '100.101.102.103');
    expect(p.sshPort, 22);
    expect(p.pairPort, 40123);
    expect(p.hostPublicKey.length, 32);
    expect(p.token.length, 32);
    expect(p.sshFingerprint, startsWith('SHA256:'));
    expect(p.expiresAt, DateTime.fromMillisecondsSinceEpoch(1000 * 1000, isUtc: true));
  });

  test('expired code is rejected, including exactly at exp', () {
    expect(
      errorOf(link(valid()), at: DateTime.fromMillisecondsSinceEpoch(1000 * 1000)),
      PairCodeError.expired,
    );
    expect(
      errorOf(link(valid()), at: DateTime.fromMillisecondsSinceEpoch(5000 * 1000)),
      PairCodeError.expired,
    );
  });

  test('wrong version is rejected', () {
    expect(errorOf(link(valid()..['v'] = 2)), PairCodeError.unsupportedVersion);
    expect(errorOf(link(valid()..remove('v'))), PairCodeError.unsupportedVersion);
  });

  test('malformed links are rejected', () {
    for (final raw in [
      '',
      'https://example.com/?d=abc',
      'openmosh://other?d=abc',
      'openmosh://pair',
      'openmosh://pair?d=***',
      'openmosh://pair?d=${b64uEncode(utf8.encode('[1]'))}',
      'openmosh://pair?d=${b64uEncode(utf8.encode('not json'))}',
    ]) {
      expect(errorOf(raw), PairCodeError.malformed, reason: raw);
    }
  });

  test('bad fields are malformed', () {
    final cases = <String, Object?>{
      'ssh_fp': 'MD5:aa',
      'hpk': b64uEncode(List<int>.filled(31, 1)),
      'tok': 'short',
      'port': 0,
      'ssh_port': 70000,
      'ssh_user': 'me; rm -rf',
      'alias': '',
      'exp': '1000',
    };
    cases.forEach((k, v) {
      expect(errorOf(link(valid()..[k] = v)), PairCodeError.malformed, reason: k);
    });
  });

  test('pairing address outside the tailnet range is refused', () {
    for (final ip in ['192.168.1.10', '100.128.0.1', '100.63.255.255', 'evil.example']) {
      expect(errorOf(link(valid()..['ip'] = ip)), PairCodeError.notTailnet, reason: ip);
    }
    expect(errorOf(link(valid()..['ip'] = '100.64.0.1')), isNull);
    expect(errorOf(link(valid()..['ip'] = '100.127.255.254')), isNull);
  });
}
