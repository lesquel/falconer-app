import '../parsing/screen_region.dart';

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
