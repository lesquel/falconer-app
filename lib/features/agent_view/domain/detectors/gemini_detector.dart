import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Gemini CLI: boxed confirmations with a `●` radio, boxed `>` input.
final class GeminiDetector extends AgentDetector {
  const GeminiDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [
    NumberedMenuScanner(cursors: '●', unchecked: '○'),
  ];

  @override
  List<InputScanner> get inputScanners => const [
    FramedPromptInput(prompts: '>', placeholders: ['Type your message or @path/to/file']),
  ];

  @override
  List<String> get noise => const ['no sandbox', 'context left)'];
}
