import 'package:sherpa_onnx/sherpa_onnx.dart';

import '../../domain/entities/voice_model.dart';

/// Threads for decoding: enough for real time on a phone, leaves cores free.
const _threads = 2;

/// sherpa-onnx configuration for [model] unpacked in [folder]. Whisper always
/// runs in transcribe mode (never translate). [language] is used only when
/// the model accepts it and lists it; otherwise the model detects it.
OfflineRecognizerConfig recognizerConfig(
  VoiceModel model, {
  required String folder,
  required String language,
}) {
  String f(ModelRole r) => '$folder/${model.files[r] ?? ''}';
  final lang = model.selectableLanguages.contains(language) ? language : '';
  final tokens = f(ModelRole.tokens);
  final OfflineModelConfig m = switch (model.family) {
    ModelFamily.whisper => OfflineModelConfig(
      whisper: OfflineWhisperModelConfig(
        encoder: f(ModelRole.encoder),
        decoder: f(ModelRole.decoder),
        language: lang,
        task: 'transcribe',
      ),
      tokens: tokens,
      numThreads: _threads,
      debug: false,
    ),
    ModelFamily.nemoTransducer || ModelFamily.transducer => OfflineModelConfig(
      transducer: OfflineTransducerModelConfig(
        encoder: f(ModelRole.encoder),
        decoder: f(ModelRole.decoder),
        joiner: f(ModelRole.joiner),
      ),
      modelType: model.family == ModelFamily.nemoTransducer ? 'nemo_transducer' : '',
      tokens: tokens,
      numThreads: _threads,
      debug: false,
    ),
    ModelFamily.moonshine => OfflineModelConfig(
      moonshine: OfflineMoonshineModelConfig(
        preprocessor: f(ModelRole.preprocessor),
        encoder: f(ModelRole.encoder),
        uncachedDecoder: f(ModelRole.uncachedDecoder),
        cachedDecoder: f(ModelRole.cachedDecoder),
      ),
      tokens: tokens,
      numThreads: _threads,
      debug: false,
    ),
    ModelFamily.senseVoice => OfflineModelConfig(
      senseVoice: OfflineSenseVoiceModelConfig(
        model: f(ModelRole.model),
        language: lang,
        useInverseTextNormalization: true,
      ),
      tokens: tokens,
      numThreads: _threads,
      debug: false,
    ),
  };
  return OfflineRecognizerConfig(model: m);
}
