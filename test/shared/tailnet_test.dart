import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/tailnet.dart';

void main() {
  test('tailnet IPv4 accepts the CGNAT range', () {
    expect(isTailnetIpv4('100.64.0.1'), isTrue);
    expect(isTailnetIpv4('100.127.255.255'), isTrue);
    expect(isTailnetIpv4('100.128.0.1'), isFalse);
    expect(isTailnetIpv4('10.0.0.1'), isFalse);
  });

  test('octets with whitespace, signs, hex or leading zeros are refused', () {
    for (final ip in [
      '100.64.0. 1',
      ' 100.64.0.1',
      '100.64.0.1\n',
      '100.+64.0.1',
      '100.-0.0.1',
      '100.64.0x0.1',
      '100.064.0.1',
      '100.64.0.1000',
      '100.64.0.256',
      '100.64.0',
      '100.64.0.1.1',
      '１００.64.0.1',
    ]) {
      expect(isTailnetIpv4(ip), isFalse, reason: ip);
      expect(isTailnetHostName(ip), isFalse, reason: ip);
    }
  });

  test('isIpv4Literal validates strict dotted quads', () {
    expect(isIpv4Literal('192.168.1.10'), isTrue);
    expect(isIpv4Literal('0.0.0.0'), isTrue);
    expect(isIpv4Literal('999.1.1.1'), isFalse);
    expect(isIpv4Literal('1.2.3. 4'), isFalse);
  });

  test('ts.net names are still tailnet host names', () {
    expect(isTailnetHostName('box.tail1.ts.net'), isTrue);
    expect(isTailnetHostName('example.com'), isFalse);
  });
}
