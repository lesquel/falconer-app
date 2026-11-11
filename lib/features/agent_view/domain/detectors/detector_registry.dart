import 'agent_detector.dart';
import 'aider_detector.dart';
import 'amp_detector.dart';
import 'claude_detector.dart';
import 'codex_detector.dart';
import 'copilot_detector.dart';
import 'cursor_detector.dart';
import 'gemini_detector.dart';
import 'generic_detector.dart';
import 'kiro_detector.dart';
import 'opencode_detector.dart';
import 'pi_detector.dart';

const _detectors = <String, AgentDetector>{
  'claude': ClaudeDetector(),
  'codex': CodexDetector(),
  'pi': PiDetector(),
  'gemini': GeminiDetector(),
  'kiro': KiroDetector(),
  'opencode': OpencodeDetector(),
  'copilot': CopilotDetector(),
  'cursor': CursorDetector(),
  'amp': AmpDetector(),
  'aider': AiderDetector(),
};

const _aliases = {
  'claude-code': 'claude',
  'kiro-cli': 'kiro',
  'cursor-agent': 'cursor',
  'gemini-cli': 'gemini',
  'copilot-cli': 'copilot',
};

/// The detector for a Herdr/hook agent id; unknown or null ids get the
/// conservative generic detector.
AgentDetector detectorFor(String? agent) {
  final id = agent?.trim().toLowerCase();
  if (id == null) return const GenericDetector();
  return _detectors[_aliases[id] ?? id] ?? const GenericDetector();
}
