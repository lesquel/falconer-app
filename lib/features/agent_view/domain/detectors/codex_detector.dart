import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../parsing/screen_region.dart';
import 'agent_detector.dart';

/// OpenAI Codex CLI: `› 1. Yes, just this once (y)` approvals, `›` composer.
final class CodexDetector extends AgentDetector {
  const CodexDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [NumberedMenuScanner(cursors: '›')];

  @override
  List<InputScanner> get inputScanners => const [
    CodexComposerInput(
      placeholders: [
        'Ask Codex to do anything',
        'Explain this codebase',
        'Summarize recent commits',
        'Implement {feature}',
        'Find and fix a bug in @filename',
        'Write tests for @filename',
        'Improve documentation in @filename',
        'Run /review on my current changes',
        'Use /skills to list available skills',
      ],
    ),
  ];

  @override
  List<String> get noise => const ['context left'];
}
