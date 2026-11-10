import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/voice/data/datasources/recognizer_config.dart';
import 'package:openmosh/features/voice/domain/entities/voice_catalog.dart';

void main() {
  test('Whisper always transcribes (never translates) in the chosen language', () {
    final m = catalogModel('whisper-base')!;
    final c = recognizerConfig(m, folder: '/models/whisper-base', language: 'es');
    expect(c.model.whisper.task, 'transcribe');
    expect(c.model.whisper.language, 'es');
    expect(
      c.model.whisper.encoder,
      '/models/whisper-base/sherpa-onnx-whisper-base/base-encoder.int8.onnx',
    );
    expect(c.model.tokens, '/models/whisper-base/sherpa-onnx-whisper-base/base-tokens.txt');
  });

  test('Whisper on Automatic leaves the language empty for detection', () {
    final c = recognizerConfig(catalogModel('whisper-small')!, folder: '/m', language: '');
    expect(c.model.whisper.task, 'transcribe');
    expect(c.model.whisper.language, '');
  });

  test('a language the model does not list falls back to automatic', () {
    final c = recognizerConfig(
      catalogModel('sense-voice-int8-2024-07-17')!,
      folder: '/m',
      language: 'es',
    );
    expect(c.model.senseVoice.language, '');
    final ok = recognizerConfig(
      catalogModel('sense-voice-int8-2024-07-17')!,
      folder: '/m',
      language: 'ja',
    );
    expect(ok.model.senseVoice.language, 'ja');
  });

  test('Parakeet runs as a NeMo transducer', () {
    final c = recognizerConfig(
      catalogModel('parakeet-tdt-0.6b-v3-int8')!,
      folder: '/m',
      language: 'es',
    );
    expect(c.model.modelType, 'nemo_transducer');
    expect(c.model.transducer.joiner, endsWith('/joiner.int8.onnx'));
  });

  test('Moonshine gets its four networks', () {
    final c = recognizerConfig(catalogModel('moonshine-tiny-en-int8')!, folder: '/m', language: '');
    expect(c.model.moonshine.preprocessor, endsWith('/preprocess.onnx'));
    expect(c.model.moonshine.cachedDecoder, endsWith('/cached_decode.int8.onnx'));
  });
}
