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
