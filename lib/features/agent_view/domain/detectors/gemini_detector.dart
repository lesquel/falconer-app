import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
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

  /// Past prompts are `> text`; tool calls are boxed `✔  ToolName ...` rows.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) {
    final user = glyphPrompt(line, '>');
    if (user != null && line.border == null) return user;
    if (line.border != null && _tool.hasMatch(line.trimmed)) return toolLine(line);
    return null;
  }
}

final _tool = RegExp(r'^[✔✓⊷✕✗] +[A-Z][A-Za-z]+\b');
