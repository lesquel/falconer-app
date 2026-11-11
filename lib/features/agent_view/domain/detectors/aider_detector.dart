import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Aider: `(Y)es/(N)o ... [Yes]:` line prompts, `> ` input.
final class AiderDetector extends AgentDetector {
  const AiderDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [AiderConfirmScanner()];

  @override
  List<InputScanner> get inputScanners => const [LinePromptInput()];

  @override
  List<String> get noise => const ['tokens:'];
}
