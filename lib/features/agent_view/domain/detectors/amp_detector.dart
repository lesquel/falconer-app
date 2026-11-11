import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Amp: boxed approval lists with a `▸` cursor, boxed input without prompt.
final class AmpDetector extends AgentDetector {
  const AmpDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [
    CursorListScanner(cursors: '▸❯→', frame: ListFrame.boxedQuestion),
  ];

  @override
  List<InputScanner> get inputScanners => const [RuleBoxInput()];
}
