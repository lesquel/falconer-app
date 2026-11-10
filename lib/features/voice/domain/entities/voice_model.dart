/// Speech model families sherpa-onnx can run offline. Each one needs its own
/// set of files from the model archive.
enum ModelFamily {
  whisper,

  /// NeMo transducers such as Parakeet TDT.
  nemoTransducer,

  /// Zipformer (icefall) transducers.
  transducer,
  moonshine,
  senseVoice;

  /// Whether the engine accepts a fixed spoken language for this family.
  bool get acceptsLanguage => this == whisper || this == senseVoice;

  /// File roles the recognizer needs, in a stable order.
  List<ModelRole> get roles => switch (this) {
    whisper => const [ModelRole.encoder, ModelRole.decoder, ModelRole.tokens],
    nemoTransducer ||
    transducer => const [ModelRole.encoder, ModelRole.decoder, ModelRole.joiner, ModelRole.tokens],
    moonshine => const [
      ModelRole.preprocessor,
      ModelRole.encoder,
      ModelRole.uncachedDecoder,
      ModelRole.cachedDecoder,
      ModelRole.tokens,
    ],
    senseVoice => const [ModelRole.model, ModelRole.tokens],
  };

  static ModelFamily? byName(String? name) => values.where((f) => f.name == name).firstOrNull;
}

/// What a file of a model archive is used for.
enum ModelRole {
  encoder,
  decoder,
  joiner,
  tokens,
  preprocessor,
  uncachedDecoder,
  cachedDecoder,
  model;

  static ModelRole? byName(String? name) => values.where((r) => r.name == name).firstOrNull;
}

/// One file of a model fetched on its own, pinned by size and SHA-256.
final class ModelPart {
  const ModelPart({
    required this.path,
    required this.url,
    required this.sizeBytes,
    required this.sha256,
  });

  /// Where the file goes, relative to the model folder (one of [VoiceModel.files]).
  final String path;

  /// HTTPS URL at an immutable revision.
  final String url;
  final int sizeBytes;

  /// Lower-case hex SHA-256 of the file.
  final String sha256;
}

/// A downloadable speech model: either the separate files it needs ([parts],
/// catalog models, nothing to unpack) or a sherpa-onnx `.tar.bz2` archive
/// pinned by its SHA-256 (custom models).
final class VoiceModel {
  const VoiceModel({
    required this.id,
    required this.name,
    required this.url,
    required this.sha256,
    required this.family,
    this.sizeBytes,
    this.languages = const [],
    this.files = const {},
    this.parts = const [],
    this.recommended = false,
    this.custom = false,
  });

  /// File-system safe identifier, also the model's folder name.
  final String id;
  final String name;

  /// The archive, or for a model made of [parts] the page they come from.
  final String url;

  /// Lower-case hex SHA-256 of the archive; empty for a model made of [parts].
  final String sha256;
  final ModelFamily family;

  /// Bytes to download (archive, or all [parts]); null for a custom model
  /// (unknown until downloaded).
  final int? sizeBytes;

  /// ISO 639-1 codes (`yue` for Cantonese, `haw` for Hawaiian); empty when unknown.
  final List<String> languages;

  /// Path of each needed file relative to the model folder. Catalog models pin
  /// them; custom models are filled in after extraction.
  final Map<ModelRole, String> files;

  /// Files downloaded one by one instead of an archive; empty for an archive.
  final List<ModelPart> parts;
  final bool recommended;
  final bool custom;

  bool get englishOnly => languages.length == 1 && languages.single == 'en';

  /// Languages the user may force; empty means "Automatic" only.
  List<String> get selectableLanguages => family.acceptsLanguage && !englishOnly ? languages : [];

  VoiceModel withFiles(Map<ModelRole, String> files) => VoiceModel(
    id: id,
    name: name,
    url: url,
    sha256: sha256,
    family: family,
    sizeBytes: sizeBytes,
    languages: languages,
    files: files,
    parts: parts,
    recommended: recommended,
    custom: custom,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'sha256': sha256,
    'family': family.name,
    'languages': languages,
    'files': {for (final e in files.entries) e.key.name: e.value},
  };

  /// A stored custom model; null when malformed.
  static VoiceModel? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final family = ModelFamily.byName(json['family'] as String?);
    final id = json['id'];
    final name = json['name'];
    final url = json['url'];
    final sha = json['sha256'];
    if (family == null || id is! String || name is! String || url is! String || sha is! String) {
      return null;
    }
    final langs = json['languages'];
    final files = json['files'];
    return VoiceModel(
      id: id,
      name: name,
      url: url,
      sha256: sha,
      family: family,
      languages: [
        if (langs is List)
          for (final l in langs)
            if (l is String) l,
      ],
      files: {
        if (files is Map)
          for (final e in files.entries)
            if (ModelRole.byName(e.key as String?) case final role? when e.value is String)
              role: e.value as String,
      },
      custom: true,
    );
  }
}
