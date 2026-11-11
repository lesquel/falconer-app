import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// OpenCode: `△ Permission required` button row, `┃` prompt box.
final class OpencodeDetector extends AgentDetector {
  const OpencodeDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [ButtonRowScanner()];

  @override
  List<InputScanner> get inputScanners => const [
    LeftBarInput(placeholders: ['Ask anything']),
  ];
}
