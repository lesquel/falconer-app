import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/voice/domain/entities/custom_model.dart';
import 'package:openmosh/features/voice/domain/entities/voice_model.dart';

void main() {
  const sha = 'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789';

  CustomModelResult make({
    String name = 'My Whisper',
    String url = 'https://example.org/m.tar.bz2',
    String hash = sha,
    String languages = '',
  }) => buildCustomModel(
    name: name,
    url: url,
    sha256: hash,
    family: ModelFamily.whisper,
    languages: languages,
    newId: () => '0123abcd',
  );

  test('a valid entry becomes a custom model with a safe id', () {
    final r = make(hash: sha.toUpperCase(), languages: 'es, EN ,  pt') as CustomModelOk;
    expect(r.model.id, 'custom-0123abcd');
    expect(r.model.custom, isTrue);
    expect(r.model.sha256, sha);
    expect(r.model.languages, ['es', 'en', 'pt']);
    expect(r.model.family, ModelFamily.whisper);
  });

  test('a URL that is not https is rejected', () {
    expect((make(url: 'http://example.org/m.tar.bz2') as CustomModelInvalid).errors, {
      CustomModelError.url,
    });
    expect((make(url: 'ftp://x/y') as CustomModelInvalid).errors, {CustomModelError.url});
    expect((make(url: 'https://') as CustomModelInvalid).errors, {CustomModelError.url});
  });

  test('the SHA-256 is required and must be 64 hex characters', () {
    for (final bad in ['', 'abc', '${sha}0', sha.replaceFirst('a', 'g')]) {
      expect((make(hash: bad) as CustomModelInvalid).errors, {
        CustomModelError.sha256,
      }, reason: bad);
    }
  });

  test('a name is required and bad language codes are rejected', () {
    expect((make(name: '  ') as CustomModelInvalid).errors, {CustomModelError.name});
    expect((make(languages: 'es, spanish!') as CustomModelInvalid).errors, {
      CustomModelError.languages,
    });
  });
}
