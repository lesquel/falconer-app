import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// GitHub Copilot CLI: `❯ 1. Yes` menus in a box, boxed `>` input.
final class CopilotDetector extends AgentDetector {
  const CopilotDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [NumberedMenuScanner(cursors: '❯>')];

  @override
  List<InputScanner> get inputScanners => const [
    FramedPromptInput(prompts: '>❯', placeholders: ['Enter @ to mention files or / for commands']),
  ];
}
