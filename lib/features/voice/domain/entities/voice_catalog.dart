import 'voice_model.dart';

const _hf = 'https://huggingface.co/csukuangfj';

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

/// A model made of separate files from a Hugging Face mirror of the
/// sherpa-onnx release, pinned at [revision] (a commit, never a branch). The
/// files keep the archive's folder name ([dir]) so models installed from the
/// archives earlier stay usable.
VoiceModel _mirror({
  required String id,
  required String name,
  required String repo,
  required String revision,
  required String dir,
  required ModelFamily family,
  required List<String> languages,
  required Map<ModelRole, (String, int, String)> files,
  bool recommended = false,
}) {
  final parts = [
    for (final (file, size, sha) in files.values)
      ModelPart(
        path: '$dir/$file',
        url: '$_hf/$repo/resolve/$revision/$file',
        sizeBytes: size,
        sha256: sha,
      ),
  ];
  return VoiceModel(
    id: id,
    name: name,
    url: '$_hf/$repo',
    sha256: '',
    family: family,
    sizeBytes: parts.fold<int>(0, (a, p) => a + p.sizeBytes),
    languages: languages,
    recommended: recommended,
    files: {for (final e in files.entries) e.key: '$dir/${e.value.$1}'},
    parts: parts,
  );
}

/// Built-in models: the int8 files of the official sherpa-onnx models (the
/// same bytes as the release archives), each file pinned by size and SHA-256.
/// Fetched one by one, so nothing has to be unpacked. Nothing here is
/// downloaded until the user asks.
final voiceCatalog = <VoiceModel>[
  _mirror(
    id: 'parakeet-tdt-0.6b-v3-int8',
    name: 'Parakeet TDT 0.6B v3',
    repo: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
    revision: 'ed5d745623472f97cfc2e6c2916ee248798fc5a8',
    dir: 'sherpa-onnx-nemo-parakeet-tdt-0.6b-v3-int8',
    family: ModelFamily.nemoTransducer,
    languages: parakeetV3Languages,
    recommended: true,
    files: {
      ModelRole.encoder: (
        'encoder.int8.onnx',
        652282294,
        '1afbe69c1ffdabee94755f42e4daf1d93549131a3da11356bda84fcef0f2c479',
      ),
      ModelRole.decoder: (
        'decoder.int8.onnx',
        11845274,
        '0222a86147299d4dee90edf95b6d13827edb42ad8b7c9cf0b2582f030937c0b5',
      ),
      ModelRole.joiner: (
        'joiner.int8.onnx',
        6355277,
        'cbd02f3696e9944970111fb439d9c3fd365a80374565f13f2b9c7007d253fc98',
      ),
      ModelRole.tokens: (
        'tokens.txt',
        93939,
        'd58544679ea4bc6ac563d1f545eb7d474bd6cfa467f0a6e2c1dc1c7d37e3c35d',
      ),
    },
  ),
  _mirror(
    id: 'whisper-tiny',
    name: 'Whisper Tiny',
    repo: 'sherpa-onnx-whisper-tiny',
    revision: '65176e2deb88badc814a94058666cadccc29b61c',
    dir: 'sherpa-onnx-whisper-tiny',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: {
      ModelRole.encoder: (
        'tiny-encoder.int8.onnx',
        12937772,
        'd24fb083ae3b1041fc24e97971d60e280c9342201fbb67b0ab428a8b4a51a434',
      ),
      ModelRole.decoder: (
        'tiny-decoder.int8.onnx',
        89855401,
        'd2fece8dd42771f1df975c6c0445770d0c292bf7547c2cae04a6c0cc57540925',
      ),
      ModelRole.tokens: (
        'tiny-tokens.txt',
        816730,
        'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
      ),
    },
  ),
  _mirror(
    id: 'whisper-base',
    name: 'Whisper Base',
    repo: 'sherpa-onnx-whisper-base',
    revision: 'bb53ee204431c90d314c1cc08d28d23e5b7927cc',
    dir: 'sherpa-onnx-whisper-base',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: {
      ModelRole.encoder: (
        'base-encoder.int8.onnx',
        29120534,
        '0b8fb1304b6109976038efff5ace81720e00386f3ff6b54ee8c75291ca0a1e11',
      ),
      ModelRole.decoder: (
        'base-decoder.int8.onnx',
        130672026,
        '9759d217388a01b3a4c7c15533201067b48ae819c4daafc8624e64b9409dc02d',
      ),
      ModelRole.tokens: (
        'base-tokens.txt',
        816730,
        'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
      ),
    },
  ),
  _mirror(
    id: 'whisper-small',
    name: 'Whisper Small',
    repo: 'sherpa-onnx-whisper-small',
    revision: '8f3c18b358db4d1f2fc1eae49d75cd20989e4309',
    dir: 'sherpa-onnx-whisper-small',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: {
      ModelRole.encoder: (
        'small-encoder.int8.onnx',
        112442483,
        '4cbe7b22fa9026b843b60a68640c747de05bafb1a11b57edc0e66c232d9f33a9',
      ),
      ModelRole.decoder: (
        'small-decoder.int8.onnx',
        262226114,
        'acad50b5c782696e91b55914cc5ab4f756f1532f76e22aa6fc615f39fb69a8ee',
      ),
      ModelRole.tokens: (
        'small-tokens.txt',
        816730,
        'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
      ),
    },
  ),
  _mirror(
    id: 'whisper-turbo',
    name: 'Whisper Turbo',
    repo: 'sherpa-onnx-whisper-turbo',
    revision: '2ca6ff69fc878651b770880507669577ac41c2ff',
    dir: 'sherpa-onnx-whisper-turbo',
    family: ModelFamily.whisper,
    languages: whisperLanguages,
    files: {
      ModelRole.encoder: (
        'turbo-encoder.int8.onnx',
        674716297,
        'b02dcdf54f348741e93fe732b67d933c8dcb6735655f710640143081db38878b',
      ),
      ModelRole.decoder: (
        'turbo-decoder.int8.onnx',
        361080764,
        '20accd02388482eb3a46bd615631adfdc85e1eb2c7db9ea3f02a40ffe6b81547',
      ),
      ModelRole.tokens: (
        'turbo-tokens.txt',
        816730,
        'b34b360dbb493e781e479794586d661700670d65564001f23024971d1f2fa126',
      ),
    },
  ),
  _mirror(
    id: 'moonshine-tiny-en-int8',
    name: 'Moonshine Tiny',
    repo: 'sherpa-onnx-moonshine-tiny-en-int8',
    revision: 'bf2b762c076d8ea61e2af0b3851c9564fb77552e',
    dir: 'sherpa-onnx-moonshine-tiny-en-int8',
    family: ModelFamily.moonshine,
    languages: ['en'],
    files: {
      ModelRole.preprocessor: (
        'preprocess.onnx',
        6800738,
        'f33addce61a143460fe753b5ee5b7db255e5140b5b779c065b94f6c83ff0bf4e',
      ),
      ModelRole.encoder: (
        'encode.int8.onnx',
        18249187,
        '8774dfba578de027ec6595c2c654a0836434489bc963a0db124a7f181f571acb',
      ),
      ModelRole.uncachedDecoder: (
        'uncached_decode.int8.onnx',
        53216096,
        '216737000dd5881a17aa043f6bbd286add33e4c3b0ae257153e2ec15438bdc41',
      ),
      ModelRole.cachedDecoder: (
        'cached_decode.int8.onnx',
        45264830,
        '2aff28bba6a03d8dcf5c9feac45462629bae37317442299f28115ad09da773f6',
      ),
      ModelRole.tokens: (
        'tokens.txt',
        436688,
        '1165c2aeb9f72f457a83be2d459a09054f27490acd9b41bd43794dfd25e296ea',
      ),
    },
  ),
  _mirror(
    id: 'sense-voice-int8-2024-07-17',
    name: 'SenseVoice Small',
    repo: 'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-2024-07-17',
    revision: '2365baeacb507f821a0c8120fcee3d484dba7a07',
    dir: 'sherpa-onnx-sense-voice-zh-en-ja-ko-yue-int8-2024-07-17',
    family: ModelFamily.senseVoice,
    languages: ['zh', 'en', 'ja', 'ko', 'yue'],
    files: {
      ModelRole.model: (
        'model.int8.onnx',
        239233841,
        'c71f0ce00bec95b07744e116345e33d8cbbe08cef896382cf907bf4b51a2cd51',
      ),
      ModelRole.tokens: (
        'tokens.txt',
        315894,
        'f449eb28dc567533d7fa59be34e2abca8784f771850c78a47fb731a31429a1dc',
      ),
    },
  ),
];

/// Built-in model with [id], or null.
VoiceModel? catalogModel(String id) => voiceCatalog.where((m) => m.id == id).firstOrNull;
