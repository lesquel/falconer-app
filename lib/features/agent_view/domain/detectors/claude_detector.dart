import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// Claude Code: `❯ 1. Yes` permission menus, `>` input between rules.
final class ClaudeDetector extends AgentDetector {
  const ClaudeDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [NumberedMenuScanner(cursors: '❯>')];

  @override
  List<InputScanner> get inputScanners => [
    FramedPromptInput(prompts: '>❯', placeholders: [RegExp(r'^Try ".*"$')]),
  ];

  @override
  List<String> get noise => const ['accept edits on', 'plan mode on', 'bypass permissions on'];
}
