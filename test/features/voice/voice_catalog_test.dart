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

  test('every catalog model is its separate files, each pinned at an immutable revision', () {
    final pinned = RegExp(r'^https://huggingface\.co/csukuangfj/[\w.-]+/resolve/[0-9a-f]{40}/');
    for (final m in voiceCatalog) {
      expect(m.parts, isNotEmpty, reason: m.id);
      expect(m.parts.map((p) => p.path).toSet(), m.files.values.toSet(), reason: m.id);
      for (final p in m.parts) {
        expect(pinned.hasMatch(p.url), isTrue, reason: p.url);
        expect(p.url, endsWith('/${p.path.split('/').last}'));
        expect(hex64.hasMatch(p.sha256), isTrue, reason: p.url);
        expect(p.sizeBytes, greaterThan(0), reason: p.url);
      }
      expect(m.sizeBytes, m.parts.fold<int>(0, (a, p) => a + p.sizeBytes), reason: m.id);
      expect(m.sizeBytes, greaterThan(1000000), reason: m.id);
      expect(m.languages, isNotEmpty, reason: m.id);
    }
  });

  test('catalog files keep the folder layout of the earlier archive downloads', () {
    // Models installed from the archives stay usable after the update.
    expect(
      catalogModel('parakeet-tdt-0.6b-v3-int8')!.files[ModelRole.encoder],
      'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/encoder.int8.onnx',
    );
    expect(
      catalogModel('sense-voice-int8-2024-07-17')!.files[ModelRole.model],
      'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17/model.int8.onnx',
    );
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
