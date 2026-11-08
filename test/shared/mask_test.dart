import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/mask.dart';

void main() {
  test('IPv4 keeps the first and last octet', () {
    expect(maskAddress('100.101.102.67'), '100.••.••.67');
  });

  test('IPv6 keeps the first and last group', () {
    expect(maskAddress('fd7a:115c:a1e0::67'), 'fd7a:••••:67');
  });

  test('host names keep two characters at each end; short ones are fully hidden', () {
    expect(maskAddress('box.tailnet.ts.net'), 'bo••••et');
    expect(maskAddress('pi'), '••••');
  });

  test('fingerprints keep the algorithm and two characters at each end', () {
    expect(maskFingerprint('SHA256:abcdefghijklmnopqrstuvwxyz'), 'SHA256:ab••••••yz');
    expect(maskFingerprint('SHA256:x'), 'SHA256:••••••');
  });

  test('public keys keep the type and the first four characters of the blob', () {
    expect(maskPublicKey('ssh-ed25519 AAAAC3NzaC1lZDI1NTE5 me@phone'), 'ssh-ed25519 AAAA••••…');
    expect(maskPublicKey('garbage'), '••••…');
  });

  test('endpoints hide the address and keep the user and port', () {
    expect(maskEndpoint('me', '100.1.2.3', 22), 'me@••••:22');
  });
}
