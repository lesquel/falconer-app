import '../parsing/choice_details.dart';
import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
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

  /// The `$ command` line of an approval.
  @override
  String? choiceDetail(List<ScreenLine> lines, ScreenRegion region) => dollarCommand(lines, region);

  @override
  List<String> get noise => const ['context left'];

  /// Past prompts are `› text`; commands, edits and tool calls are history
  /// cells headed `• Ran`, `• Explored`, `• Edited` ... with `└` output.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) {
    final user = glyphPrompt(line, '›');
    if (user != null) return user;
    if (line.indent == 0 && _tool.hasMatch(line.text)) return toolLine(line);
    if (current == null && line.trimmed.startsWith('└')) return toolLine(line);
    return null;
  }
}

final _tool = RegExp(
  r'^• (?:Ran|Running|Explored|Exploring|Edited|Added|Deleted|Called|Calling|Waited|'
  r'Interacted|Searched|Updated Plan)\b',
);
