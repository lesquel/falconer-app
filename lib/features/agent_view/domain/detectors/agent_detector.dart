import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';

const _commonNoise = [
  '? for shortcuts',
  'esc to interrupt',
  'esc to cancel',
  'press enter to confirm',
  'ctrl+o to',
  'shift+tab to cycle',
  '↑↓ navigate',
];

/// Compiled [AgentDetector.noise] matchers, one per detector type.
final _noisePatterns = <Type, RegExp>{};

/// How one agent draws its menus, input line and status lines.
///
/// Every scanner must be conservative: when it is not sure, it returns null
/// and the lines stay text.
abstract class AgentDetector {
  const AgentDetector();

  /// Tried in order; the first match wins.
  List<ChoiceScanner> get choiceScanners;

  /// Tried in order when no menu is showing; the first match wins.
  List<InputScanner> get inputScanners;

  /// Whether [line] starts a paragraph of a known speaker (S12). [current] is
  /// the role of the paragraph being built, null when [line] starts one.
  /// Null keeps the line in the current paragraph or, when it starts one,
  /// gives it the default role. Never guess: unsure lines are agent text.
  RoleStart? roleStart(ScreenLine line, TextRole? current) => null;

  /// Role of unmarked paragraphs after a user line (a shell's output).
  TextRole get afterUser => TextRole.agent;

  /// A user line stands alone (a shell command); the next line starts a new
  /// paragraph.
  bool get userIsOneLine => false;

  /// Lower-case fragments of status or footer lines to drop.
  List<String> get noise => const [];

  bool isNoise(String trimmed) {
    if (trimmed.isEmpty || trimmed.length > 160) return false;
    final pattern = _noisePatterns[runtimeType] ??= RegExp(
      [..._commonNoise, ...noise].map(RegExp.escape).join('|'),
      caseSensitive: false,
    );
    return pattern.hasMatch(trimmed);
  }
}
