import '../parsing/choice_details.dart';
import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
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

  /// The command under `Bash command`, or the path under `Edit file`.
  @override
  String? choiceDetail(List<ScreenLine> lines, ScreenRegion region) => detailUnderHeader(
    lines,
    region,
    paragraphHeaders: const {'Bash command'},
    lineHeaders: const {'Edit file', 'Create file'},
  );

  @override
  List<String> get noise => const ['accept edits on', 'plan mode on', 'bypass permissions on'];

  /// Past prompts are `❯ text` (`> ` without Unicode); tool calls are
  /// `● Name(args)` (`⏺` on macOS) with `⎿` output rows.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) {
    final user = glyphPrompt(line, '❯>');
    if (user != null) return user;
    if (line.indent == 0 && _tool.hasMatch(line.text)) return toolLine(line);
    if (current == null && line.trimmed.startsWith('⎿')) return toolLine(line);
    return null;
  }
}

final _tool = RegExp(r'^[⏺●] (?:[A-Z][A-Za-z0-9_]*\(|.+ \(MCP\)\()');
