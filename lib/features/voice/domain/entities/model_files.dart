import 'voice_model.dart';

String _base(String path) => path.split('/').last.toLowerCase();

bool _onnx(String b) => b.endsWith('.onnx');

/// Whether [path] can hold [role] for [family], by its file name.
bool _matches(ModelFamily family, ModelRole role, String path) {
  final b = _base(path);
  if (role == ModelRole.tokens) return b.endsWith('tokens.txt');
  if (!_onnx(b)) return false;
  return switch ((family, role)) {
    (ModelFamily.moonshine, ModelRole.preprocessor) => b.startsWith('preprocess'),
    (ModelFamily.moonshine, ModelRole.encoder) => b.startsWith('encode'),
    (ModelFamily.moonshine, ModelRole.uncachedDecoder) => b.startsWith('uncached_decode'),
    (ModelFamily.moonshine, ModelRole.cachedDecoder) => b.startsWith('cached_decode'),
    (ModelFamily.senseVoice, ModelRole.model) => b.startsWith('model'),
    (_, ModelRole.encoder) => b.contains('encoder'),
    (_, ModelRole.decoder) => b.contains('decoder'),
    (_, ModelRole.joiner) => b.contains('joiner'),
    _ => false,
  };
}

/// Finds the files [family] needs among the extracted [paths] (relative,
/// `/`-separated). Prefers int8 weights, then the shortest name. Returns the
/// roles that could not be found as [MissingModelFiles].
Map<ModelRole, String> detectModelFiles(ModelFamily family, Iterable<String> paths) {
  final all = paths.toList();
  final found = <ModelRole, String>{};
  final missing = <ModelRole>[];
  for (final role in family.roles) {
    final candidates = all.where((p) => _matches(family, role, p)).toList()
      ..sort((a, b) {
        final ai = _base(a).contains('.int8.') ? 0 : 1;
        final bi = _base(b).contains('.int8.') ? 0 : 1;
        return ai != bi ? ai - bi : a.length - b.length;
      });
    if (candidates.isEmpty) {
      missing.add(role);
    } else {
      found[role] = candidates.first;
    }
  }
  if (missing.isNotEmpty) throw MissingModelFiles(missing);
  return found;
}

/// The archive lacks files the recognizer needs.
final class MissingModelFiles implements Exception {
  const MissingModelFiles(this.roles);
  final List<ModelRole> roles;

  @override
  String toString() => 'Missing model files: ${roles.map((r) => r.name).join(', ')}';
}
