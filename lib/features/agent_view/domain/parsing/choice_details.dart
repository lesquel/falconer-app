import 'dart:math' as math;

import 'screen_line.dart';
import 'screen_region.dart';

/// Index of a menu's question line: the consumed line above the menu.
int? questionLine(ScreenRegion region) {
  final above = region.consumed.where((i) => i < region.at);
  return above.isEmpty ? null : above.reduce(math.max);
}

/// The paragraph (or first line) under the nearest [headers] line above
/// the question, within [window] lines. Claude draws `Bash command` with the
/// command and its description under it, and `Edit file` with the path.
String? detailUnderHeader(
  List<ScreenLine> lines,
  ScreenRegion region, {
  required Set<String> paragraphHeaders,
  required Set<String> lineHeaders,
  int window = 14,
}) {
  final question = questionLine(region);
  if (question == null) return null;
  for (var h = question - 1; h >= math.max(0, question - window); h--) {
    final header = lines[h].trimmed;
    final paragraph = paragraphHeaders.contains(header);
    if (!paragraph && !lineHeaders.contains(header)) continue;
    final body = <ScreenLine>[];
    for (var k = h + 1; k < question; k++) {
      final line = lines[k];
      if (line.isBlank || line.isRule) {
        if (body.isEmpty) continue;
        break;
      }
      body.add(line);
      if (!paragraph) break;
    }
    if (body.isEmpty) return null;
    final indent = body.map((l) => l.indent).reduce(math.min);
    return body.map((l) => l.text.substring(indent)).join('\n');
  }
  return null;
}

/// The single `$ command` line between the question and the menu (Codex).
String? dollarCommand(List<ScreenLine> lines, ScreenRegion region) {
  final question = questionLine(region);
  if (question == null) return null;
  String? found;
  for (var k = question + 1; k < region.at; k++) {
    final t = lines[k].trimmed;
    if (!t.startsWith(r'$ ')) continue;
    if (found != null) return null;
    found = t.substring(2).trim();
  }
  return found == null || found.isEmpty ? null : found;
}
