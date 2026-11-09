import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/logging/redacting_logger.dart';

void main() {
  test('redacts keys, tokens, links and endpoints', () {
    // Assembled at run time so secret scanners do not mistake this
    // placeholder (no key material) for a committed private key.
    const kind = 'OPENSSH PRIVATE KEY';
    const pem = '-----BEGIN $kind-----\nb3BlbnNzaC1rZXktdjEAAAAA\n-----END $kind-----';
    final out = redact(
      'key=$pem pub=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDRX tok=gIGCg4SFhoeIiYqLjI2Oj5CRkpOU '
      'link=openmosh://pair?v=2&t=eyJ2IjoxfQ url=https://ntfy.sh/upSecretTopic',
    );
    for (final leak in [
      'BEGIN OPENSSH',
      'AAAAC3Nza',
      'gIGCg4SFhoeI',
      'eyJ2IjoxfQ',
      'upSecretTopic',
    ]) {
      expect(out, isNot(contains(leak)), reason: leak);
    }
    expect(out, contains('[redacted]'));
  });

  test('keeps short, non-secret text readable', () {
    expect(redact('connected host=h1'), 'connected host=h1');
  });
}
