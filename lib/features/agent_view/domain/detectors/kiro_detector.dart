import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
import 'agent_detector.dart';

/// Kiro CLI: `Allow this action? ... [y/n/t]:` line prompts, `> ` input.
final class KiroDetector extends AgentDetector {
  const KiroDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [BracketConfirmScanner()];

  @override
  List<InputScanner> get inputScanners => const [LinePromptInput()];

  /// The REPL echoes each sent prompt as a `> text` line.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) => glyphPrompt(line, '>');
}
