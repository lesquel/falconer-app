import 'voice_model.dart';

const _release = 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models';

/// The 99 languages of the multilingual Whisper models.
const whisperLanguages = [
  'en', 'zh', 'de', 'es', 'ru', 'ko', 'fr', 'ja', 'pt', 'tr', 'pl', 'ca', 'nl', 'ar', //
  'sv', 'it', 'id', 'hi', 'fi', 'vi', 'he', 'uk', 'el', 'ms', 'cs', 'ro', 'da', 'hu', //
  'ta', 'no', 'th', 'ur', 'hr', 'bg', 'lt', 'la', 'mi', 'ml', 'cy', 'sk', 'te', 'fa', //
  'lv', 'bn', 'sr', 'az', 'sl', 'kn', 'et', 'mk', 'br', 'eu', 'is', 'hy', 'ne', 'mn', //
  'bs', 'kk', 'sq', 'sw', 'gl', 'mr', 'pa', 'si', 'km', 'sn', 'yo', 'so', 'af', 'oc', //
  'ka', 'be', 'tg', 'sd', 'gu', 'am', 'yi', 'lo', 'uz', 'fo', 'ht', 'ps', 'tk', 'nn', //
  'mt', 'sa', 'lb', 'my', 'bo', 'tl', 'mg', 'as', 'tt', 'haw', 'ln', 'ha', 'ba', 'jw', 'su',
];

/// The 25 European languages of Parakeet TDT 0.6B v3.
const parakeetV3Languages = [
  'bg', 'hr', 'cs', 'da', 'nl', 'en', 'et', 'fi', 'fr', 'de', 'el', 'hu', 'it', //
  'lv', 'lt', 'mt', 'pl', 'pt', 'ro', 'sk', 'sl', 'es', 'sv', 'ru', 'uk',
];

Map<ModelRole, String> _whisper(String dir, String prefix) => {
  ModelRole.encoder: '$dir/$prefix-encoder.int8.onnx',
  ModelRole.decoder: '$dir/$prefix-decoder.int8.onnx',
  ModelRole.tokens: '$dir/$prefix-tokens.txt',
};

/// Built-in models: official sherpa-onnx release archives, each pinned by
/// size and SHA-256. Nothing here is downloaded until the user asks.
final voiceCatalog = <VoiceModel>[
  const VoiceModel(
    id: 'parakeet-tdt-0.6b-v3-int8',
    name: 'Parakeet TDT 0.6B v3',
    url: '$_release/sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8.tar.bz2',
    sizeBytes: 487211443,
    sha256: '1495e91b59d7fc53ddca91f3431758ec99f8fa253fdb0e1e851be0f72b14b0f9',
    family: ModelFamily.nemoTransducer,
    languages: parakeetV3Languages,
    recommended: true,
    files: {
      ModelRole.encoder: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/encoder.int8.onnx',
      ModelRole.decoder: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/decoder.int8.onnx',
      ModelRole.joiner: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/joiner.int8.onnx',
      ModelRole.tokens: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8/tokens.txt',
    },
  ),
  VoiceModel(
    id: 'whisper-tiny',
    name: 'Whisper Tiny',
    url: '$_release/sherpa-onnx-whisper-tiny.tar.bz2',
    sizeBytes: 116204861,
    sha256: 'c46116994e539aa165266d96b325252728429c12535eb9d8b6a2b10f129e66b1',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: _whisper('sherpa-onnx-whisper-tiny', 'tiny'),
  ),
  VoiceModel(
    id: 'whisper-base',
    name: 'Whisper Base',
    url: '$_release/sherpa-onnx-whisper-base.tar.bz2',
    sizeBytes: 207557382,
    sha256: '911b2083efd7c0dca2ac3b358b75222660dc09fb716d64fbfc417ba6c99ff3de',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: _whisper('sherpa-onnx-whisper-base', 'base'),
  ),
  VoiceModel(
    id: 'whisper-small',
    name: 'Whisper Small',
    url: '$_release/sherpa-onnx-whisper-small.tar.bz2',
    sizeBytes: 639387718,
    sha256: '486a46afbb7ba798507190ffe02fea2dd726049af212e774537efac6afb210a6',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: _whisper('sherpa-onnx-whisper-small', 'small'),
  ),
  VoiceModel(
    id: 'whisper-turbo',
    name: 'Whisper Turbo',
    url: '$_release/sherpa-onnx-whisper-turbo.tar.bz2',
    sizeBytes: 563790207,
    sha256: 'b11acbbcd660b44a8e0df33724feb5aaa709cf65668f2823d59f656312544f22',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: _whisper('sherpa-onnx-whisper-turbo', 'turbo'),
  ),
  const VoiceModel(
    id: 'moonshine-tiny-en-int8',
    name: 'Moonshine Tiny',
    url: '$_release/sherpa-onnx-moonshine-tiny-en-int8.tar.bz2',
    sizeBytes: 107600538,
    sha256: 'd5fe6ec4334fef36255b2a4010412cad4c007e33103fec62fb5d17cad88086f2',
    family: ModelFamily.moonshine,
    languages: ['en'],
    files: {
      ModelRole.preprocessor: 'sherpa-onnx-moonshine-tiny-en-int8/preprocess.onnx',
      ModelRole.encoder: 'sherpa-onnx-moonshine-tiny-en-int8/encode.int8.onnx',
      ModelRole.uncachedDecoder: 'sherpa-onnx-moonshine-tiny-en-int8/uncached_decode.int8.onnx',
      ModelRole.cachedDecoder: 'sherpa-onnx-moonshine-tiny-en-int8/cached_decode.int8.onnx',
      ModelRole.tokens: 'sherpa-onnx-moonshine-tiny-en-int8/tokens.txt',
    },
  ),
  const VoiceModel(
    id: 'sense-voice-int8-2024-07-17',
    name: 'SenseVoice Small',
    url: '$_release/sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17.tar.bz2',
    sizeBytes: 163002883,
    sha256: '7d1efa2138a65b0b488df37f8b89e3d91a60676e416f515b952358d83dfd347e',
    family: ModelFamily.senseVoice,
    languages: ['zh', 'en', 'ja', 'ko', 'yue'],
    files: {
      ModelRole.model: 'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17/model.int8.onnx',
      ModelRole.tokens: 'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17/tokens.txt',
    },
  ),
];

/// Built-in model with [id], or null.
VoiceModel? catalogModel(String id) => voiceCatalog.where((m) => m.id == id).firstOrNull;
