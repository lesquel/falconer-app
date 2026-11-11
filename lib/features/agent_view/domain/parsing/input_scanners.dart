import 'dart:math' as math;

import '../entities/screen_block.dart';
import 'screen_line.dart';
import 'screen_region.dart';

/// Text an agent shows dimmed in an empty input; read as an empty draft.
bool _isPlaceholder(String draft, List<Pattern> placeholders) {
  for (final p in placeholders) {
    if (p is String ? draft.startsWith(p) : p.matchAsPrefix(draft) != null) return true;
  }
  return false;
}

ScreenRegion _input(int at, List<ScreenLine> lines, String draft, List<Pattern> placeholders) =>
    ScreenRegion(
      at: at,
      consumed: span(at, lines.length),
      block: InputBlock(_isPlaceholder(draft, placeholders) ? '' : draft),
    );

String _dedent(Iterable<ScreenLine> content) {
  final lines = content.toList();
  var min = 1 << 30;
  for (final l in lines) {
    if (!l.isBlank) min = math.min(min, l.indent);
  }
  return lines
      .map((l) => l.isBlank ? '' : l.text.substring(math.min(min, l.text.length)))
      .join('\n')
      .trim();
}

/// A prompt glyph line framed by rules or a box (Claude, Gemini, Copilot,
/// Cursor):
///
/// ```text
/// ──────────────
/// > draft text
///   continued
/// ──────────────
/// ```
final class FramedPromptInput implements InputScanner {
  const FramedPromptInput({required this.prompts, this.placeholders = const [], this.window = 12});

  final String prompts;
  final List<Pattern> placeholders;
  final int window;

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final stop = math.max(1, lines.length - window);
    for (var p = lines.length - 1; p >= stop; p--) {
      final line = lines[p];
      if (line.isBlank || line.isRule || !lines[p - 1].isRule) continue;
      final s = line.text.trimLeft();
      if (!prompts.contains(s[0]) || (s.length > 1 && s.codeUnitAt(1) != 0x20)) continue;
      var end = p + 1;
      while (end < lines.length && end < p + 40 && !lines[end].isRule) {
        end++;
      }
      if (end >= lines.length || !lines[end].isRule) continue;
      final cut = line.indent + 2;
      final draft = [
        s.substring(1).trim(),
        for (var k = p + 1; k < end; k++)
          lines[k].text.substring(math.min(cut, lines[k].indent)).trimRight(),
      ].join('\n').trim();
      return _input(p - 1, lines, draft, placeholders);
    }
    return null;
  }
}

/// Codex's composer: a `›` line near the bottom with its footer below.
final class CodexComposerInput implements InputScanner {
  const CodexComposerInput({this.placeholders = const []});

  final List<Pattern> placeholders;

  static final _option = RegExp(r'^› [1-9][.)] ');
  static const _footer = ['context left', 'for shortcuts', '⏎ send'];

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final stop = math.max(0, lines.length - 10);
    for (var p = lines.length - 1; p >= stop; p--) {
      final s = lines[p].text.trimLeft();
      if (s.isEmpty || s[0] != '›' || (s.length > 1 && s.codeUnitAt(1) != 0x20)) continue;
      if (_option.hasMatch(s)) return null;
      var footer = false;
      for (var k = p + 1; k < lines.length && !footer; k++) {
        final lower = lines[k].trimmed.toLowerCase();
        footer = _footer.any(lower.contains);
      }
      if (!footer) return null;
      final cut = lines[p].indent + 2;
      final draft = [
        s.substring(1).trim(),
        for (var k = p + 1; k < lines.length && !lines[k].isBlank && lines[k].indent >= cut; k++)
          lines[k].text.substring(cut),
      ].join('\n').trim();
      return _input(p, lines, draft, placeholders);
    }
    return null;
  }
}

/// An editor drawn between two rules near the bottom, with no prompt glyph
/// (Pi, Amp). Content that looks like a menu hint is never an input.
final class RuleBoxInput implements InputScanner {
  const RuleBoxInput({this.placeholders = const [], this.maxFooter = 4});

  final List<Pattern> placeholders;
  final int maxFooter;

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    var footer = 0;
    var bottom = lines.length - 1;
    while (bottom >= 0 && !lines[bottom].isRule) {
      if (!lines[bottom].isBlank && ++footer > maxFooter) return null;
      bottom--;
    }
    if (bottom < 0) return null;
    var top = bottom - 1;
    while (top >= 0 && top >= bottom - 31 && !lines[top].isRule) {
      top--;
    }
    if (top < 0 || !lines[top].isRule || bottom - top < 2) return null;
    final content = lines.sublist(top + 1, bottom);
    if (content.any((l) => isHintLine(l.trimmed))) return null;
    return _input(top, lines, _dedent(content), placeholders);
  }
}

/// OpenCode's prompt: lines behind a `┃` bar, the last one naming the agent
/// and model, closed by a `╹▀▀▀` rule.
final class LeftBarInput implements InputScanner {
  const LeftBarInput({this.placeholders = const []});

  final List<Pattern> placeholders;

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final stop = math.max(0, lines.length - 8);
    for (var m = lines.length - 1; m >= stop; m--) {
      if (!lines[m].isRule || !lines[m].raw.contains('▀')) continue;
      var start = m;
      while (start > 0 && lines[start - 1].border == '┃') {
        start--;
      }
      if (start == m) return null;
      final content = lines.sublist(start, m).where((l) => !l.isBlank).toList();
      if (content.isNotEmpty) content.removeLast(); // agent and model line
      return _input(start, lines, _dedent(content), placeholders);
    }
    return null;
  }
}

/// A bare line prompt at the very bottom: `> draft`, `ask> draft`, `!> draft`
/// (Aider, Kiro).
final class LinePromptInput implements InputScanner {
  const LinePromptInput();

  static final _prompt = RegExp(r'^(?:[a-z]+|!)?> ?(.*)$');

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    for (var p = lines.length - 1; p >= 0; p--) {
      if (lines[p].isBlank) continue;
      final m = _prompt.firstMatch(lines[p].text);
      if (m == null) return null;
      return _input(p, lines, m.group(1)!.trim(), const []);
    }
    return null;
  }
}
