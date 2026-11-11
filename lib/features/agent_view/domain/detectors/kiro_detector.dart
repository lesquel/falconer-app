import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Kiro CLI: `Allow this action? ... [y/n/t]:` line prompts, `> ` input.
final class KiroDetector extends AgentDetector {
  const KiroDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [BracketConfirmScanner()];

  @override
  List<InputScanner> get inputScanners => const [LinePromptInput()];
}
