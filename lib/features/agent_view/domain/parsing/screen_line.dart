/// One visible line of an agent screen with its box-drawing frame removed.
library;

const _verticals = '│┃║';
const _boxGlyphs = '─━═╭╮╰╯┌┐└┘├┤┬┴┼│┃║╹╻╵╷╴╶▀▄▔▁╌╍┄┅┈┉';

final class ScreenLine {
  ScreenLine(this.text, {this.raw = '', this.isRule = false, this.border}) : trimmed = text.trim();

  /// The line as received, right-trimmed.
  final String raw;

  /// Content without the box sides, right-trimmed. Empty for rules.
  final String text;

  /// A horizontal border or separator (only box-drawing glyphs).
  final bool isRule;

  /// The vertical border glyph the line started with, when it was boxed.
  final String? border;

  bool get isBlank => !isRule && trimmed.isEmpty;

  /// [text] without surrounding spaces.
  final String trimmed;

  int get indent {
    var i = 0;
    while (i < text.length && text.codeUnitAt(i) == 0x20) {
      i++;
    }
    return i;
  }
}

List<ScreenLine> normalizeScreen(List<String> lines) => [for (final l in lines) _normalize(l)];

ScreenLine _normalize(String raw) {
  final original = (raw.contains('\t') ? raw.replaceAll('\t', '    ') : raw).trimRight();
  var text = original;
  String? border;
  // Peel up to three nested frames (`│ │ text │ │`).
  for (var pass = 0; pass < 3; pass++) {
    final start = _firstNonSpace(text);
    if (start < 0 || !_verticals.contains(text[start])) break;
    border ??= text[start];
    text = text.substring(start + 1).trimRight();
    if (text.isNotEmpty && _verticals.contains(text[text.length - 1])) {
      text = text.substring(0, text.length - 1).trimRight();
    }
  }
  final body = text.trim();
  if (body.isEmpty) return ScreenLine('', raw: original, border: border);
  if (_isRule(body)) return ScreenLine('', raw: original, isRule: true, border: border);
  return ScreenLine(text, raw: original, border: border);
}

int _firstNonSpace(String s) {
  for (var i = 0; i < s.length; i++) {
    if (s.codeUnitAt(i) != 0x20) return i;
  }
  return -1;
}

final _boxUnits = _boxGlyphs.codeUnits.toSet();
const _space = 0x20;
const _horizontal = 0x2500; // ─

bool _isRule(String body) {
  for (var i = 0; i < body.length; i++) {
    final c = body.codeUnitAt(i);
    if (c != _space && !_boxUnits.contains(c)) {
      // Scroll separators such as `─── ↑ 3 more ─────`.
      return body.startsWith('───') && body.codeUnitAt(body.length - 1) == _horizontal;
    }
  }
  return true;
}
