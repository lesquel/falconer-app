/// Helpers for detectors that recognize who wrote a line (S12): the user's
/// prompt, a tool call, or the agent. Unsure lines get no role (agent).
library;

import '../entities/screen_block.dart';
import 'screen_line.dart';

/// A line that starts a paragraph of [role]. [line] is the line to keep: for
/// a user prompt, its glyph replaced by spaces so continuation lines align.
typedef RoleStart = ({TextRole role, ScreenLine line});

/// [line] as a user prompt whose first [glyph] characters (after the
/// indentation) are the prompt.
RoleStart userPrompt(ScreenLine line, int glyph) {
  final at = line.indent;
  final text = line.text.replaceRange(at, at + glyph, ' ' * glyph);
  return (role: TextRole.user, line: ScreenLine(text, raw: line.raw, border: line.border));
}

/// [line] replaced by [text] alone as a user prompt (a shell command).
RoleStart userText(ScreenLine line, String text) =>
    (role: TextRole.user, line: ScreenLine(text, raw: line.raw, border: line.border));

RoleStart toolLine(ScreenLine line) => (role: TextRole.tool, line: line);

/// A prompt line: [glyphs] at column 0 then a space and text, never a
/// numbered menu option (`❯ 1. Yes`).
RoleStart? glyphPrompt(ScreenLine line, String glyphs) {
  final t = line.text;
  if (line.indent != 0 || t.length < 3 || !glyphs.contains(t[0]) || t[1] != ' ') return null;
  if (t[2] == ' ' || _option.hasMatch(t.substring(2))) return null;
  return userPrompt(line, 2);
}

final _option = RegExp(r'^[1-9][.)] ');
