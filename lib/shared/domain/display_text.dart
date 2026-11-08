/// Cleaning of short labels received from a host (aliases, names) before they
/// are stored or shown.
library;

/// Control (Cc), format (Cf: bidi overrides/isolates, zero-width, BOM) and
/// line/paragraph separator (Zl, Zp) characters.
final _invisible = RegExp(r'[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]', unicode: true);

/// Space separators (NBSP, en/em spaces, ideographic space…), shown as U+0020.
final _space = RegExp(r'\p{Zs}', unicode: true);

/// Removes invisible characters, normalizes spaces and trims. Returns null when
/// the result is longer than [max] characters (code units).
String? sanitizeLabel(String raw, {int max = 64}) {
  final clean = raw.replaceAll(_invisible, '').replaceAll(_space, ' ').trim();
  return clean.length > max ? null : clean;
}

/// Ids received from a host (events, devices): b64u characters only, so they
/// can never carry `/`, `..` or control characters into routes or prompts.
bool isWireId(Object? id, {int max = 128}) =>
    id is String && id.isNotEmpty && id.length <= max && _wireId.hasMatch(id);

final _wireId = RegExp(r'^[A-Za-z0-9_-]+$');

/// Cleans longer host-provided text (event titles and summaries, agent titles,
/// paths, project and device names) for display: strips the characters
/// [sanitizeLabel] strips (with C1 and bidi controls), keeps line feeds when
/// [multiline], and cuts at [max] characters with a visible `…`.
String sanitizeText(String raw, {required int max, bool multiline = false}) {
  final text = raw
      .replaceAll('\r\n', '\n')
      .replaceAll('\t', ' ')
      .replaceAllMapped(_invisible, (m) => multiline && m[0] == '\n' ? '\n' : '')
      .replaceAll(_space, ' ')
      .trim();
  return truncateText(text, max);
}

/// [text] cut to [max] characters (Unicode code points, never half a
/// surrogate pair), ending in `…` when something was cut.
String truncateText(String text, int max) {
  final runes = text.runes;
  if (runes.length <= max) return text;
  return '${String.fromCharCodes(runes.take(max - 1))}…';
}
