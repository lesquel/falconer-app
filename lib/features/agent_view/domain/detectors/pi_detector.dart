import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
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
}
