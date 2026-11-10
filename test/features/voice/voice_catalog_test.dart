import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/voice/domain/entities/model_files.dart';
import 'package:openmosh/features/voice/domain/entities/voice_catalog.dart';
import 'package:openmosh/features/voice/domain/entities/voice_model.dart';

void main() {
  final hex64 = RegExp(r'^[0-9a-f]{64}$');
  final safeId = RegExp(r'^[a-z0-9][a-z0-9._-]*$');

  test('catalog ids are unique and file-system safe', () {
    final ids = voiceCatalog.map((m) => m.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final id in ids) {
      expect(safeId.hasMatch(id), isTrue, reason: id);
    }
  });

  test('every catalog model is an https sherpa-onnx release with a pinned size and SHA-256', () {
    for (final m in voiceCatalog) {
      expect(
        m.url,
        startsWith('https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'),
      );
      expect(m.url, endsWith('.tar.bz2'));
      expect(hex64.hasMatch(m.sha256), isTrue, reason: m.id);
      expect(m.sizeBytes, greaterThan(1000000), reason: m.id);
      expect(m.languages, isNotEmpty, reason: m.id);
    }
  });

  test('catalog models pin every file their family needs, and detection agrees', () {
    for (final m in voiceCatalog) {
      expect(m.files.keys.toSet(), m.family.roles.toSet(), reason: m.id);
      expect(detectModelFiles(m.family, m.files.values), m.files, reason: m.id);
      for (final p in m.files.values) {
        expect(p.startsWith('/') || p.split('/').contains('..'), isFalse, reason: p);
      }
    }
  });

  test('the catalog has the approved models with Parakeet v3 recommended', () {
    final ids = voiceCatalog.map((m) => m.id).toSet();
    expect(
      ids,
      containsAll([
        'parakeet-tdt-0.6b-v3-int8',
        'whisper-base',
        'whisper-small',
        'whisper-turbo',
        'moonshine-tiny-en-int8',
      ]),
    );
    expect(voiceCatalog.where((m) => m.recommended).map((m) => m.id), [
      'parakeet-tdt-0.6b-v3-int8',
    ]);
    expect(catalogModel('parakeet-tdt-0.6b-v3-int8')!.languages, hasLength(25));
    expect(catalogModel('whisper-base')!.languages, hasLength(99));
  });

  test('English-only models are flagged and offer no fixed language', () {
    final moon = catalogModel('moonshine-tiny-en-int8')!;
    expect(moon.englishOnly, isTrue);
    expect(moon.selectableLanguages, isEmpty);
    expect(catalogModel('whisper-base')!.englishOnly, isFalse);
    expect(catalogModel('whisper-base')!.selectableLanguages, contains('es'));
    // Parakeet detects the language itself: Automatic only.
    expect(catalogModel('parakeet-tdt-0.6b-v3-int8')!.selectableLanguages, isEmpty);
  });

  group('detectModelFiles', () {
    test('prefers int8 weights for Whisper', () {
      final files = detectModelFiles(ModelFamily.whisper, [
        'w/base-encoder.onnx',
        'w/base-encoder.int8.onnx',
        'w/base-decoder.onnx',
        'w/base-decoder.int8.onnx',
        'w/base-tokens.txt',
        'w/test_wavs/0.wav',
      ]);
      expect(files, {
        ModelRole.encoder: 'w/base-encoder.int8.onnx',
        ModelRole.decoder: 'w/base-decoder.int8.onnx',
        ModelRole.tokens: 'w/base-tokens.txt',
      });
    });

    test('fails clearly when a needed file is missing', () {
      expect(
        () => detectModelFiles(ModelFamily.nemoTransducer, ['m/encoder.onnx', 'm/tokens.txt']),
        throwsA(
          isA<MissingModelFiles>().having((e) => e.roles, 'roles', [
            ModelRole.decoder,
            ModelRole.joiner,
          ]),
        ),
      );
    });
  });
}
