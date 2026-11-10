import 'voice_model.dart';

enum CustomModelError { name, url, sha256, languages }

sealed class CustomModelResult {
  const CustomModelResult();
}

final class CustomModelOk extends CustomModelResult {
  const CustomModelOk(this.model);
  final VoiceModel model;
}

final class CustomModelInvalid extends CustomModelResult {
  const CustomModelInvalid(this.errors);
  final Set<CustomModelError> errors;
}

final _hex64 = RegExp(r'^[0-9a-f]{64}$');
final _lang = RegExp(r'^[a-z]{2,3}$');

/// Validates the "Add model" form. The archive must come over HTTPS and be
/// pinned by its SHA-256, like the built-in models.
CustomModelResult buildCustomModel({
  required String name,
  required String url,
  required String sha256,
  required ModelFamily family,
  required String languages,
  required String Function() newId,
}) {
  final errors = <CustomModelError>{};
  final n = name.trim();
  if (n.isEmpty || n.length > 64) errors.add(CustomModelError.name);
  final u = Uri.tryParse(url.trim());
  if (u == null || u.scheme != 'https' || u.host.isEmpty || u.userInfo.isNotEmpty) {
    errors.add(CustomModelError.url);
  }
  final hash = sha256.trim().toLowerCase();
  if (!_hex64.hasMatch(hash)) errors.add(CustomModelError.sha256);
  final langs = [
    for (final l in languages.split(',')) ?(l.trim().isEmpty ? null : l.trim().toLowerCase()),
  ];
  if (!langs.every(_lang.hasMatch)) errors.add(CustomModelError.languages);
  if (errors.isNotEmpty) return CustomModelInvalid(errors);
  return CustomModelOk(
    VoiceModel(
      id: 'custom-${newId()}',
      name: n,
      url: u!.toString(),
      sha256: hash,
      family: family,
      languages: langs.toSet().toList(),
      custom: true,
    ),
  );
}
