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

/// Lower-case [AgentDetector.noise] fragments with the common ones, one list
/// per detector type.
final _noiseFragments = <Type, List<String>>{};

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

  /// The input line disappears while a menu waits for an answer, so an
  /// input line under a menu means the menu was answered.
  bool get menuHidesInput => false;

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

  /// The command or file a recognized menu is about, when this agent draws
  /// it in a way the detector is sure of; null otherwise.
  String? choiceDetail(List<ScreenLine> lines, ScreenRegion region) => null;

  /// Lower-case fragments of status or footer lines to drop.
  List<String> get noise => const [];

  /// A case-insensitive substring match. Only ASCII letters fold, as in a
  /// non-unicode case-insensitive RegExp, but without its cost on every line
  /// of a long screen.
  bool isNoise(String trimmed) {
    if (trimmed.isEmpty || trimmed.length > 160) return false;
    final fragments = _noiseFragments[runtimeType] ??= [
      for (final f in [..._commonNoise, ...noise]) f.toLowerCase(),
    ];
    for (final f in fragments) {
      if (_containsFolded(trimmed, f)) return true;
    }
    return false;
  }
}

/// Whether [s], with A-Z lowered, contains [lower] (already lower-case).
bool _containsFolded(String s, String lower) {
  final n = lower.length;
  if (n == 0) return true;
  final first = lower.codeUnitAt(0);
  for (var i = 0, last = s.length - n; i <= last; i++) {
    if (_fold(s.codeUnitAt(i)) != first) continue;
    var k = 1;
    while (k < n && _fold(s.codeUnitAt(i + k)) == lower.codeUnitAt(k)) {
      k++;
    }
    if (k == n) return true;
  }
  return false;
}

int _fold(int c) => c >= 0x41 && c <= 0x5A ? c + 0x20 : c;
