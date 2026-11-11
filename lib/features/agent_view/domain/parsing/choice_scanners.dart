import 'dart:math' as math;

import '../entities/screen_block.dart';
import 'choice_kind_classifier.dart';
import 'screen_line.dart';
import 'screen_region.dart';

final _numbered = RegExp(r'^([1-9])[.)]\s+(\S.*)$');

/// A numbered menu with exactly one cursor and a question above it:
///
/// ```text
///  Do you want to proceed?
///  ❯ 1. Yes
///    2. No, and tell Claude what to do differently (esc)
/// ```
///
/// Each option is picked with its digit.
final class NumberedMenuScanner implements ChoiceScanner {
  const NumberedMenuScanner({
    required this.cursors,
    this.unchecked = '',
    this.requireHint = false,
    this.questionWindow = 14,
    this.maxTrailing = 3,
    this.searchWindow = 40,
  });

  /// Glyphs marking the selected option (`❯`, `›`, `●` ...).
  final String cursors;

  /// Glyphs marking an unselected option (`○`), ignored.
  final String unchecked;

  /// Also demand a key-hint line under the menu (generic detector).
  final bool requireHint;
  final int questionWindow;

  /// Non-hint lines allowed below the menu; more means the menu is stale.
  final int maxTrailing;
  final int searchWindow;

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final stop = math.max(0, lines.length - searchWindow);
    for (var i = lines.length - 1; i >= stop; i--) {
      if (_option(lines[i])?.number != 1) continue;
      final region = _menuAt(lines, i);
      if (region != null) return region;
    }
    return null;
  }

  _Option? _option(ScreenLine line) {
    if (line.isBlank || line.isRule) return null;
    var s = line.text.trimLeft();
    var cursor = false;
    if (s.length > 2 && s.codeUnitAt(1) == 0x20) {
      final mark = s[0];
      if (cursors.contains(mark) || unchecked.contains(mark)) {
        cursor = cursors.contains(mark);
        s = s.substring(2).trimLeft();
      }
    }
    final m = _numbered.firstMatch(s);
    if (m == null) return null;
    return _Option(int.parse(m.group(1)!), m.group(2)!, cursor: cursor, indent: line.indent);
  }

  ScreenRegion? _menuAt(List<ScreenLine> lines, int start) {
    final options = <_Option>[];
    var j = start;
    while (j < lines.length) {
      final line = lines[j];
      final option = _option(line);
      if (option != null) {
        if (option.number != options.length + 1) break;
        options.add(option);
        j++;
        continue;
      }
      if (line.isBlank) {
        final next = j + 1 < lines.length ? _option(lines[j + 1]) : null;
        if (next?.number == options.length + 1) {
          j++;
          continue;
        }
        break;
      }
      if (line.isRule || isHintLine(line.trimmed) || line.indent <= options.last.indent) break;
      options.last.label += ' ${line.trimmed}';
      j++;
    }
    if (options.length < 2 || options.where((o) => o.cursor).length != 1) return null;

    var trailing = 0;
    var hint = false;
    for (var k = j; k < lines.length; k++) {
      final line = lines[k];
      if (line.isBlank || line.isRule) continue;
      if (isHintLine(line.trimmed)) {
        hint = true;
      } else {
        trailing++;
      }
    }
    if (trailing > maxTrailing || (requireHint && !hint)) return null;

    final question = _questionAbove(lines, start, questionWindow);
    if (question == null) return null;

    return ScreenRegion(
      at: start,
      consumed: {question, ...span(start, lines.length)},
      block: ChoiceBlock(lines[question].trimmed, [
        for (final o in options)
          ChoiceOption(
            stripShortcut(o.label),
            ['${o.number}'],
            o.cursor,
            classifyChoice(stripShortcut(o.label)),
          ),
      ]),
    );
  }
}

final class _Option {
  _Option(this.number, this.label, {required this.cursor, required this.indent});

  final int number;
  String label;
  final bool cursor;
  final int indent;
}

/// Index of the nearest line ending with `?` above [start], within [window]
/// lines and without crossing a rule when [stopAtRule].
int? _questionAbove(List<ScreenLine> lines, int start, int window, {bool stopAtRule = false}) {
  final stop = math.max(0, start - window);
  for (var k = start - 1; k >= stop; k--) {
    final line = lines[k];
    if (line.isRule) {
      if (stopAtRule) return null;
      continue;
    }
    if (line.isBlank) continue;
    if (line.trimmed.endsWith('?')) return k;
  }
  return null;
}

/// How a [CursorListScanner] knows the list is a live menu.
enum ListFrame {
  /// A key-hint line (`↑↓ navigate  enter select  esc cancel`) follows the
  /// list; the title lines above it form the question (Pi selectors).
  keyHint,

  /// The list is inside a box with a `?` line above it (Cursor, Amp).
  boxedQuestion,
}

/// An unnumbered list where one row carries a cursor glyph and the others
/// are indented to the same label column. Options are picked with arrows
/// from the current selection, then enter.
final class CursorListScanner implements ChoiceScanner {
  const CursorListScanner({required this.cursors, required this.frame, this.searchWindow = 20});

  final String cursors;
  final ListFrame frame;
  final int searchWindow;

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final stop = math.max(0, lines.length - searchWindow);
    for (var i = lines.length - 1; i >= stop; i--) {
      final line = lines[i];
      final col = line.indent;
      if (!_isCursorRow(line, col)) continue;
      final region = _listAt(lines, i, col);
      if (region != null) return region;
    }
    return null;
  }

  bool _isCursorRow(ScreenLine line, int col) {
    final t = line.text;
    return !line.isBlank &&
        t.length > col + 2 &&
        cursors.contains(t[col]) &&
        t.codeUnitAt(col + 1) == 0x20 &&
        t.codeUnitAt(col + 2) != 0x20;
  }

  bool _isPlainRow(ScreenLine line, int col) {
    final t = line.text;
    return !line.isBlank &&
        line.indent == col + 2 &&
        t.length > col + 2 &&
        t.codeUnitAt(col + 2) != 0x20;
  }

  bool _isItem(ScreenLine line, int col) => _isCursorRow(line, col) || _isPlainRow(line, col);

  ScreenRegion? _listAt(List<ScreenLine> lines, int at, int col) {
    var up = at;
    while (up > 0 && _isItem(lines[up - 1], col)) {
      up--;
    }
    var down = at;
    while (down + 1 < lines.length && _isItem(lines[down + 1], col)) {
      down++;
    }
    final rows = lines.sublist(up, down + 1);
    if (rows.length < 2) return null;
    if (rows.where((r) => _isCursorRow(r, col)).length != 1) return null;
    final selected = at - up;

    final Set<int> questionLines;
    switch (frame) {
      case ListFrame.keyHint:
        if (!_hintBelow(lines, down)) return null;
        questionLines = _titleAbove(lines, up);
      case ListFrame.boxedQuestion:
        if (rows.any((r) => r.border == null)) return null;
        final q = _questionAbove(lines, up, 6, stopAtRule: true);
        if (q == null || lines[q].border == null) return null;
        questionLines = {q};
    }
    if (questionLines.isEmpty) return null;

    final options = <ChoiceOption>[];
    for (var k = 0; k < rows.length; k++) {
      final keys = arrowKeys(selected, k);
      if (keys == null) return null;
      final label = stripShortcut(rows[k].text.substring(col + 2).trim());
      options.add(ChoiceOption(label, keys, k == selected, classifyChoice(label)));
    }
    final ordered = questionLines.toList()..sort();
    return ScreenRegion(
      at: up,
      consumed: {...questionLines, ...span(up, lines.length)},
      block: ChoiceBlock(ordered.map((k) => lines[k].trimmed).join('\n'), options),
    );
  }

  bool _hintBelow(List<ScreenLine> lines, int down) {
    var seen = 0;
    for (var k = down + 1; k < lines.length && seen < 4; k++) {
      if (lines[k].isBlank) continue;
      if (isHintLine(lines[k].trimmed)) return true;
      seen++;
    }
    return false;
  }

  /// Up to two groups of title lines above the list, stopping at a rule.
  Set<int> _titleAbove(List<ScreenLine> lines, int up) {
    final found = <int>{};
    var groups = 0;
    var inGroup = false;
    for (var k = up - 1; k >= 0 && found.length < 8; k--) {
      final line = lines[k];
      if (line.isRule) break;
      if (line.isBlank) {
        if (inGroup) {
          groups++;
          inGroup = false;
          if (groups == 2) break;
        }
        continue;
      }
      inGroup = true;
      found.add(k);
    }
    return found;
  }
}

/// OpenCode's permission dialog: a `Permission required` header and one row
/// of buttons, `Allow once   Allow always   Reject`, moved with left/right.
/// The highlighted button is only a background color, so the parser assumes
/// the default (first) one; reject uses esc, which works from any button.
final class ButtonRowScanner implements ChoiceScanner {
  const ButtonRowScanner();

  static const _labels = ['Allow once', 'Allow always', 'Reject'];

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final stop = math.max(0, lines.length - 20);
    for (var row = lines.length - 1; row >= stop; row--) {
      final t = lines[row].trimmed;
      final a = t.indexOf(_labels[0]);
      final b = t.indexOf(_labels[1]);
      final c = t.indexOf(_labels[2]);
      if (a < 0 || b <= a || c <= b) continue;
      for (var h = row - 1; h >= math.max(0, row - 20); h--) {
        if (!lines[h].trimmed.endsWith('Permission required')) continue;
        return ScreenRegion(
          at: row,
          consumed: {h, ...span(row, lines.length)},
          block: const ChoiceBlock('Permission required', [
            ChoiceOption('Allow once', ['enter'], true, ChoiceKind.allow),
            ChoiceOption('Allow always', ['right', 'enter'], false, ChoiceKind.allowAlways),
            ChoiceOption('Reject', ['esc'], false, ChoiceKind.deny),
          ]),
        );
      }
      return null;
    }
    return null;
  }
}

const _yes = ChoiceOption('Yes', ['y', 'enter'], false, ChoiceKind.allow);
const _no = ChoiceOption('No', ['n', 'enter'], false, ChoiceKind.deny);

/// Aider's line confirmation: `Run shell command? (Y)es/(N)o/(D)on't ask again [Yes]:`.
/// Only Yes and No are offered: the other answers need keys outside the
/// pane key allowlist.
final class AiderConfirmScanner implements ChoiceScanner {
  const AiderConfirmScanner();

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final k = _promptLine(lines, 2, (t) => t.contains('(Y)es/(N)o'));
    if (k == null) return null;
    final t = lines[k].trimmed;
    final question = t.substring(0, t.indexOf('(Y)es')).trim();
    if (!question.endsWith('?')) return null;
    final yesDefault = t.contains('[Yes]');
    final noDefault = t.contains('[No]');
    return ScreenRegion(
      at: k,
      consumed: span(k, lines.length),
      block: ChoiceBlock(question, [
        ChoiceOption(_yes.label, _yes.keys, yesDefault, _yes.kind),
        ChoiceOption(_no.label, _no.keys, noDefault, _no.kind),
      ]),
    );
  }
}

/// A `[y/n]` or `[y/n/t]` line prompt (Kiro). The trust answer `t` is not
/// in the pane key allowlist, so only Yes and No are offered.
final class BracketConfirmScanner implements ChoiceScanner {
  const BracketConfirmScanner();

  @override
  ScreenRegion? scan(List<ScreenLine> lines) {
    final k = _promptLine(lines, 4, (t) => t.contains('[y/n/t]') || t.contains('[y/n]'));
    if (k == null) return null;
    final t = lines[k].trimmed;
    final q = t.indexOf('?');
    if (q < 0 || q > t.indexOf('[y/n')) return null;
    return ScreenRegion(
      at: k,
      consumed: span(k, lines.length),
      block: ChoiceBlock(t.substring(0, q + 1), const [_yes, _no]),
    );
  }
}

/// Index of a line matching [test] among the last [depth] non-blank lines.
int? _promptLine(List<ScreenLine> lines, int depth, bool Function(String) test) {
  var seen = 0;
  for (var k = lines.length - 1; k >= 0 && seen < depth; k--) {
    if (lines[k].isBlank || lines[k].isRule) continue;
    if (test(lines[k].trimmed)) return k;
    seen++;
  }
  return null;
}
