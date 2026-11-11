import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
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

  /// The REPL echoes each sent prompt as a `> text` line.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) => glyphPrompt(line, '>');
}
