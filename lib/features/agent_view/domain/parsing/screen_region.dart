import '../entities/screen_block.dart';
import 'screen_line.dart';

/// A recognized part of the screen: [block] is emitted at line [at] and the
/// [consumed] lines are not repeated as text.
final class ScreenRegion {
  const ScreenRegion({required this.at, required this.consumed, required this.block});

  final int at;
  final Set<int> consumed;
  final ScreenBlock block;
}

/// Finds one kind of decision menu. Returns null unless it is confident.
abstract interface class ChoiceScanner {
  ScreenRegion? scan(List<ScreenLine> lines);
}

/// Finds the agent's input line. Returns null unless it is confident.
abstract interface class InputScanner {
  ScreenRegion? scan(List<ScreenLine> lines);
}

/// Every index from [from] (inclusive) to [to] (exclusive).
Set<int> span(int from, int to) => {for (var i = from; i < to; i++) i};

/// Pane key names allowed by the hook's `pane.keys` op.
const allowedKeys = {
  'enter', 'esc', 'tab', 'space', 'backspace', 'up', 'down', 'left', 'right', 'y', 'n', //
  '1', '2', '3', '4', '5', '6', '7', '8', '9',
};

/// Maximum keys in one `pane.keys` call.
const maxKeys = 8;

/// Keys that move a vertical cursor from [from] to [to] and confirm.
List<String>? arrowKeys(int from, int to) {
  final steps = (to - from).abs();
  if (steps + 1 > maxKeys) return null;
  return [for (var i = 0; i < steps; i++) to > from ? 'down' : 'up', 'enter'];
}

const _hintMarkers = [
  'esc to cancel',
  'esc cancel',
  'cancel with esc',
  'press enter',
  'enter to confirm',
  'enter confirm',
  'enter select',
  'enter to select',
  '↑↓',
  'navigate',
  'confirm with',
  'tab to amend',
];

/// A key-hint line under a menu (`Esc to cancel`, `↑↓ navigate ...`).
bool isHintLine(String trimmed) {
  if (trimmed.isEmpty || trimmed.length > 120) return false;
  final lower = trimmed.toLowerCase();
  return _hintMarkers.any(lower.contains);
}

/// Removes a trailing shortcut annotation such as ` (esc)` or ` (y)`.
String stripShortcut(String label) => label.replaceFirst(_shortcut, '').trimRight();

final _shortcut = RegExp(
  r'\s+\((?:esc or n|shift\+tab|esc|tab|enter|[a-z])\)$',
  caseSensitive: false,
);
