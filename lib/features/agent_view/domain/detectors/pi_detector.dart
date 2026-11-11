import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
import 'agent_detector.dart';

/// Pi: selectors with a `→ ` cursor and an `↑↓ navigate` hint, editor
/// between two rules above the footer.
final class PiDetector extends AgentDetector {
  const PiDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [
    CursorListScanner(cursors: '→', frame: ListFrame.keyHint),
  ];

  @override
  List<InputScanner> get inputScanners => const [RuleBoxInput()];

  /// A tool box starts (after its padding line) with `$ command` or
  /// `read|edit|write|ls <path>`. Pi
  /// marks user messages only with a background color, which the plain text
  /// does not keep, so they stay agent text.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) =>
      current == null && line.indent <= 1 && _tool.hasMatch(line.trimmed) ? toolLine(line) : null;
}

final _tool = RegExp(r'^(?:\$ \S|(?:read|edit|write|ls) \S+$)');
