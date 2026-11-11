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
  final region =
      _firstMatch(detector.choiceScanners, screen) ?? _firstMatch(detector.inputScanners, screen);
  return _assemble(screen, region, detector);
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
  void flush() {
    if (paragraph.isEmpty) return;
    blocks.add(TextBlock(_paragraphText(paragraph)));
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
