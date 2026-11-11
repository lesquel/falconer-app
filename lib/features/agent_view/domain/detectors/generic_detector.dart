import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Unknown agents: only menus with a cursor, a question above and a key
/// hint below, and only a `>` input framed by rules.
final class GenericDetector extends AgentDetector {
  const GenericDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [
    NumberedMenuScanner(cursors: '❯›>●→▸', unchecked: '○', requireHint: true),
    CursorListScanner(cursors: '→❯▸', frame: ListFrame.keyHint),
  ];

  @override
  List<InputScanner> get inputScanners => const [FramedPromptInput(prompts: '>❯')];
}
