import '../detectors/agent_detector.dart';
import '../detectors/detector_registry.dart';
import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/screen_region.dart';

/// Turns the visible [lines] of an agent's pane into blocks the graphic view
/// renders: menus as [ChoiceBlock]s, the input line as an [InputBlock], and
/// everything else as [TextBlock] paragraphs without borders or status noise.
///
/// [agent] is the agent id Herdr reports (`claude`, `codex`, `pi` ...). When
/// a detector is not sure a menu is live, the screen stays text: a
/// [ChoiceBlock] is never guessed.
List<ScreenBlock> parseAgentScreen(String? agent, List<String> lines) {
  final screen = normalizeScreen(lines);
  final detector = detectorFor(agent);
  final menu = _firstMatch(detector.choiceScanners, screen);
  final input = _firstMatch(detector.inputScanners, screen);
  final region = menu != null && !_answered(screen, menu, input, detector) ? menu : input;
  return _assemble(screen, _withDetail(screen, region, detector), detector);
}

/// A menu with newer output under it was already answered: the agent wrote
/// a new paragraph after it (a tool call, a prompt) or, for an agent that
/// hides its input line while a menu waits, shows that input line again.
/// Only a menu that is still the last thing on the screen is live.
bool _answered(
  List<ScreenLine> screen,
  ScreenRegion menu,
  ScreenRegion? input,
  AgentDetector detector,
) {
  if (detector.menuHidesInput && input != null && input.at > menu.at) return true;
  for (var i = menu.at + 1; i < screen.length; i++) {
    if (detector.roleStart(screen[i], TextRole.agent) != null) return true;
  }
  return false;
}

/// Adds the command or file a menu is about; its lines stay as text too.
ScreenRegion? _withDetail(List<ScreenLine> screen, ScreenRegion? region, AgentDetector detector) {
  final block = region?.block;
  if (region == null || block is! ChoiceBlock) return region;
  final detail = detector.choiceDetail(screen, region);
  if (detail == null) return region;
  return ScreenRegion(at: region.at, consumed: region.consumed, block: block.withDetail(detail));
}

ScreenRegion? _firstMatch(List<Object> scanners, List<ScreenLine> screen) {
  for (final scanner in scanners) {
    final region = switch (scanner) {
      final ChoiceScanner s => s.scan(screen),
      final InputScanner s => s.scan(screen),
      _ => null,
    };
    if (region != null) return region;
  }
  return null;
}

List<ScreenBlock> _assemble(List<ScreenLine> screen, ScreenRegion? region, AgentDetector detector) {
  final blocks = <ScreenBlock>[];
  final paragraph = <ScreenLine>[];
  var role = TextRole.agent;
  // Role of paragraphs without a speaker mark (a shell's output after a command).
  var unmarked = TextRole.agent;
  void flush() {
    if (paragraph.isEmpty) return;
    blocks.add(TextBlock(_paragraphText(paragraph), role: role));
    paragraph.clear();
  }

  for (var i = 0; i < screen.length; i++) {
    if (region != null && i == region.at) {
      flush();
      blocks.add(region.block);
    }
    final line = screen[i];
    if ((region?.consumed.contains(i) ?? false) ||
        line.isBlank ||
        line.isRule ||
        detector.isNoise(line.trimmed)) {
      flush();
      continue;
    }
    final start = detector.roleStart(line, paragraph.isEmpty ? null : role);
    if (start != null) {
      flush();
      role = start.role;
      paragraph.add(start.line);
      if (role == TextRole.user) {
        unmarked = detector.afterUser;
        if (detector.userIsOneLine) flush();
      }
      continue;
    }
    if (paragraph.isEmpty) role = unmarked;
    paragraph.add(line);
  }
  flush();
  return blocks;
}

String _paragraphText(List<ScreenLine> lines) {
  var indent = lines.first.indent;
  for (final l in lines) {
    if (l.indent < indent) indent = l.indent;
  }
  return lines.map((l) => l.text.substring(indent)).join('\n');
}
