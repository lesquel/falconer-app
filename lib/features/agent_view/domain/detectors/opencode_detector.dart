import '../parsing/choice_scanners.dart';
import '../parsing/input_scanners.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';
import '../parsing/text_roles.dart';
import 'agent_detector.dart';

/// OpenCode: `△ Permission required` button row, `┃` prompt box.
final class OpencodeDetector extends AgentDetector {
  const OpencodeDetector();

  @override
  List<ChoiceScanner> get choiceScanners => const [ButtonRowScanner()];

  @override
  List<InputScanner> get inputScanners => const [
    LeftBarInput(placeholders: ['Ask anything']),
  ];

  /// User messages sit behind a `┃` bar like the prompt box; the agent's
  /// replies have no bar.
  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) =>
      line.border == '┃' && current != TextRole.user ? (role: TextRole.user, line: line) : null;
}
