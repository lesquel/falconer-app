import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/pairing/domain/entities/pair_payload.dart';
import 'package:openmosh/shared/domain/b64u.dart';

/// Builds a v3 pairing link; a null value omits the parameter.
String link(Map<String, String?> q) {
  final query = [
    for (final e in q.entries)
      if (e.value != null) '${e.key}=${Uri.encodeQueryComponent(e.value!)}',
  ].join('&');
  return 'openmosh://pair?$query';
}

Map<String, String?> valid() => {
  'v': '3',
  'i': '100.101.102.103',
  'k': b64uEncode(List<int>.filled(32, 7)),
  'p': '40123',
  't': b64uEncode(List<int>.filled(16, 9)),
};

PairCodeError? errorOf(String raw) {
  try {
    PairPayload.parse(raw);
    return null;
  } on PairCodeFailure catch (e) {
    return e.reason;
  }
}

void main() {
  test('parses a valid code', () {
    final p = PairPayload.parse(link(valid()));
    expect(p.ip, '100.101.102.103');
    expect(p.pairPort, 40123);
    expect(p.hostPublicKey, List<int>.filled(32, 7));
    expect(p.token, List<int>.filled(16, 9));
  });

  test('code from falconer-hook fits a small QR', () {
    final longest = link({
      ...valid(),
      'i': '100.100.100.100',
      'p': '65535',
      'k': b64uEncode(List<int>.filled(32, 255)),
      't': b64uEncode(List<int>.filled(16, 255)),
    });
    expect(errorOf(longest), isNull);
    // Version 6 at error correction L holds 134 bytes.
    expect(longest.length, lessThanOrEqualTo(134));
  });

  test('other versions are rejected', () {
    for (final v in ['1', '2', '4']) {
      expect(errorOf(link(valid()..['v'] = v)), PairCodeError.unsupportedVersion, reason: v);
    }
    expect(errorOf(link(valid()..remove('v'))), PairCodeError.unsupportedVersion);
    expect(errorOf('openmosh://pair?d=eyJ2IjoxfQ'), PairCodeError.unsupportedVersion);
  });

  test('malformed links are rejected', () {
    for (final raw in [
      '',
      '100.88.77.66:36141',
      'https://example.com/?v=3',
      'openmosh://other?v=3',
      'openmosh://pair',
      'openmosh://pair?v=3',
      '${link(valid())}&t=other',
      '${link(valid())}&n=extra',
      '${link(valid())}&v=3',
      link(valid()).replaceFirst('//pair', '//user@pair'),
      link(valid()).replaceFirst('//pair', '//pair:99'),
      link(valid()).replaceFirst('pair?', 'pair/x?'),
      '${link(valid())}#frag',
    ]) {
      expect(errorOf(raw), PairCodeError.malformed, reason: raw);
    }
  });

  test('bad fields are malformed', () {
    final cases = <String, String?>{
      'k': b64uEncode(List<int>.filled(31, 1)),
      't': b64uEncode(List<int>.filled(32, 1)),
      'p': '0',
      'i': null,
    };
    cases.forEach((k, v) {
      expect(errorOf(link(valid()..[k] = v)), PairCodeError.malformed, reason: k);
    });
    for (final port in ['0', '-1', '65536', '01', ' 1', '1.5', 'x', '']) {
      expect(errorOf(link(valid()..['p'] = port)), PairCodeError.malformed, reason: port);
    }
    expect(errorOf(link(valid()..['p'] = '65535')), isNull);
  });

  test('pairing address outside the tailnet range is refused', () {
    for (final ip in ['192.168.1.10', '100.128.0.1', '100.63.255.255', 'evil.example']) {
      expect(errorOf(link(valid()..['i'] = ip)), PairCodeError.notTailnet, reason: ip);
    }
    expect(errorOf(link(valid()..['i'] = '100.64.0.1')), isNull);
    expect(errorOf(link(valid()..['i'] = '100.127.255.254')), isNull);
  });

  test('ip octets must be plain decimal digits', () {
    for (final ip in ['100.64.0. 1', '100.64.+0.1', '100.64.0.1 ', '100.064.0.1', '100.64..1']) {
      expect(errorOf(link(valid()..['i'] = ip)), isNot(isNull), reason: ip);
    }
  });
}
