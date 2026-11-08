import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/pairing/domain/entities/pair_payload.dart';
import 'package:openmosh/shared/domain/b64u.dart';

/// Builds a v2 pairing link; a null value omits the parameter.
String link(Map<String, String?> q) {
  final query = [
    for (final e in q.entries)
      if (e.value != null) '${e.key}=${Uri.encodeQueryComponent(e.value!)}',
  ].join('&');
  return 'openmosh://pair?$query';
}

Map<String, String?> valid() => {
  'v': '2',
  'n': 'workstation',
  'i': '100.101.102.103',
  's': '22',
  'u': 'me',
  'f': 'i2cBF5DBtTy5_U7Y27668_2F1HhY_qwC4eALG8QAiQM',
  'k': b64uEncode(List<int>.filled(32, 7)),
  'p': '40123',
  't': b64uEncode(List<int>.filled(32, 9)),
  'e': '1000',
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
    expect(p.sshFingerprint, 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM');
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
    expect(errorOf(link(valid()..['v'] = '1')), PairCodeError.unsupportedVersion);
    expect(errorOf(link(valid()..['v'] = '3')), PairCodeError.unsupportedVersion);
    expect(errorOf(link(valid()..remove('v'))), PairCodeError.unsupportedVersion);
    // v1 codes carried the whole offer in `d`.
    expect(errorOf('openmosh://pair?d=eyJ2IjoxfQ'), PairCodeError.unsupportedVersion);
  });

  test('malformed links are rejected', () {
    for (final raw in [
      '',
      'https://example.com/?d=abc',
      'openmosh://other?d=abc',
      'openmosh://pair',
      'openmosh://pair?v=2',
      '${link(valid())}&n=other',
      '${link(valid())}&x=1',
    ]) {
      expect(errorOf(raw), PairCodeError.malformed, reason: raw);
    }
  });

  test('bad fields are malformed', () {
    final cases = <String, String?>{
      'f': 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM',
      'k': b64uEncode(List<int>.filled(31, 1)),
      't': 'short',
      'p': '0',
      's': '70000',
      'u': 'me; rm -rf',
      'n': '',
      'i': null,
    };
    cases.forEach((k, v) {
      expect(errorOf(link(valid()..[k] = v)), PairCodeError.malformed, reason: k);
    });
  });

  test('pairing address outside the tailnet range is refused', () {
    for (final ip in ['192.168.1.10', '100.128.0.1', '100.63.255.255', 'evil.example']) {
      expect(errorOf(link(valid()..['i'] = ip)), PairCodeError.notTailnet, reason: ip);
    }
    expect(errorOf(link(valid()..['i'] = '100.64.0.1')), isNull);
    expect(errorOf(link(valid()..['i'] = '100.127.255.254')), isNull);
  });

  test('exp that is not a positive in-range integer is malformed, never a crash', () {
    for (final exp in <String?>[
      '0',
      '-1',
      '1.5',
      null,
      'true',
      '01000',
      ' 1000',
      '${900 + 86400 + 1}',
      '${1 << 62}',
      '99999999999999999999999',
    ]) {
      expect(errorOf(link(valid()..['e'] = exp)), PairCodeError.malformed, reason: '$exp');
    }
    expect(errorOf(link(valid()..['e'] = '${900 + 86400}')), isNull);
  });

  test('QR alias is cleaned of format and separator characters', () {
    final p = PairPayload.parse(link(valid()..['n'] = '\u2067work\u00A0station\uFEFF'), now: now);
    expect(p.alias, 'work station');
    expect(errorOf(link(valid()..['n'] = '\u200B\u200B')), PairCodeError.malformed);
  });

  test('ip octets must be plain decimal digits', () {
    for (final ip in ['100.64.0. 1', '100.64.+0.1', '100.64.0.1 ', '100.064.0.1', '100.64..1']) {
      expect(errorOf(link(valid()..['i'] = ip)), isNot(isNull), reason: ip);
      expect(errorOf(link(valid()..['i'] = ip)), isNot(PairCodeError.expired), reason: ip);
    }
  });
}
