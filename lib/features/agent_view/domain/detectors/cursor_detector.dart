import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Cursor agent CLI: boxed `→ Run (once) (y)` lists, boxed `→` input.
final class CursorDetector extends AgentDetector {
  const CursorDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [
    CursorListScanner(cursors: '→', frame: ListFrame.boxedQuestion),
  ];

  @override
  List<InputScanner> get inputScanners => const [
    FramedPromptInput(prompts: '→', placeholders: ['Plan, search, build anything']),
  ];
}
