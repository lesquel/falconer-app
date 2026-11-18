import '../entities/agent_entry.dart';
import '../entities/screen_block.dart';

/// What [block] is, from the markers each agent draws. Anything unrecognized
/// stays a plain message or plain output: a kind is never guessed.
AgentEntry entryFor(TextBlock block) => switch (block.role) {
  TextRole.user => UserEntry(block.text),
  TextRole.tool => _toolEntry(block.text),
  TextRole.agent => _agentEntry(block.text),
};

// Tool headers, one per agent family.
final _claudeCall = RegExp(r'^[⏺●]\s+([^\s(]+)(?: \(MCP\))?\((.*?)\)?$');
final _codexCell = RegExp(
  r'^•\s+(Ran|Running|Edited|Added|Deleted|Explored|Exploring|Searched|Called|Calling|Waited|'
  r'Interacted|Updated Plan)\b\s*(.*)$',
);
final _geminiRow = RegExp(r'^([✔✓⊷✕✗])\s+([A-Z][A-Za-z]+)\s*(.*)$');
final _piCommand = RegExp(r'^\$\s+(.+)$');
final _piFile = RegExp(r'^(read|ls|edit|write)\s+(\S+)$');
final _aiderEdit = RegExp(r'^Applied edit to (.+)$');
final _aiderCommit = RegExp(r'^Commit [0-9a-f]{7,} ');
final _opencodeSearch = RegExp(r'^✱\s+(?:Grep|Glob)\s+(.+)$');
final _opencodeTool = RegExp(r'^%\s+(?:WebFetch|Patch)\b');

final _counts = RegExp(r'\s*\(\+(\d+) -(\d+)\)\s*$');
final _diffRow = RegExp(r'^\s*\d+\s?([-+])\s?(.*)$');
final _contextRow = RegExp(r'^\s*\d+\s{2,}(.*)$');
final _failure = RegExp(r'^(?:Error: )?Exit code [1-9]|^Error:');
final _outputGlyph = RegExp(r'^\s*[⎿└]\s*');

const _claudeEdits = {'Update', 'Edit', 'MultiEdit', 'Write', 'NotebookEdit'};
const _claudeReads = {'Read', 'LS', 'NotebookRead'};
const _claudeSearches = {'Grep', 'Glob', 'Search', 'WebSearch', 'WebFetch'};
const _geminiCommands = {'Shell', 'RunShellCommand'};
const _geminiEdits = {'WriteFile', 'Edit', 'Replace'};
const _geminiReads = {'ReadFile', 'ReadManyFiles', 'ReadFolder', 'ListDirectory'};
const _geminiSearches = {'SearchText', 'FindFiles', 'GoogleSearch', 'WebFetch', 'Grep', 'Glob'};

AgentEntry _toolEntry(String text) {
  final lines = text.split('\n');
  final head = lines.first.trim();
  final output = _outputLines(lines.skip(1).toList());

  final claude = _claudeCall.firstMatch(head);
  if (claude != null) return _claudeEntry(head, claude[1]!, claude[2]!, output);
  final codex = _codexCell.firstMatch(head);
  if (codex != null) return _codexEntry(codex[1]!, codex[2]!, output);
  final gemini = _geminiRow.firstMatch(head);
  if (gemini != null) return _geminiEntry(head, gemini[1]!, gemini[2]!, gemini[3]!, output);

  final command = _piCommand.firstMatch(head);
  if (command != null) return _command(command[1]!, output);
  final file = _piFile.firstMatch(head);
  if (file != null) {
    return switch (file[1]!) {
      'edit' || 'write' => _edit(file[2]!, output),
      _ => ActivityEntry(ActivityKind.read, file[2]!, detail: output),
    };
  }
  final applied = _aiderEdit.firstMatch(head);
  if (applied != null) return EditEntry(applied[1]!.trim());
  if (_aiderCommit.hasMatch(head)) return ActivityEntry(ActivityKind.other, head);
  final search = _opencodeSearch.firstMatch(head);
  if (search != null) return ActivityEntry(ActivityKind.search, search[1]!.trim(), detail: output);
  if (_opencodeTool.hasMatch(head)) {
    return ActivityEntry(ActivityKind.other, head.substring(1).trim(), detail: output);
  }
  return OutputEntry(_outputLines(lines));
}

AgentEntry _claudeEntry(String head, String name, String args, List<String> output) {
  if (name == 'Bash') return _command(args, output);
  if (_claudeEdits.contains(name)) return _edit(args, output);
  if (_claudeReads.contains(name)) return ActivityEntry(ActivityKind.read, args, detail: output);
  if (_claudeSearches.contains(name)) {
    return ActivityEntry(ActivityKind.search, args, detail: output);
  }
  return ActivityEntry(ActivityKind.other, _withoutGlyph(head), detail: output);
}

AgentEntry _codexEntry(String verb, String rest, List<String> output) => switch (verb) {
  'Ran' => _command(rest, output),
  'Running' => _command(rest, output, state: CommandState.running),
  'Edited' || 'Added' || 'Deleted' => _edit(rest, output),
  'Explored' ||
  'Exploring' => ActivityEntry(ActivityKind.read, rest.isEmpty ? verb : rest, detail: output),
  'Searched' => ActivityEntry(ActivityKind.search, rest.isEmpty ? verb : rest, detail: output),
  _ => ActivityEntry(ActivityKind.other, rest.isEmpty ? verb : '$verb $rest', detail: output),
};

AgentEntry _geminiEntry(String head, String glyph, String name, String rest, List<String> output) {
  if (_geminiCommands.contains(name)) {
    final state = switch (glyph) {
      '✔' || '✓' => CommandState.succeeded,
      '✕' || '✗' => CommandState.failed,
      _ => CommandState.running,
    };
    return CommandEntry(rest, output: output, state: state);
  }
  if (_geminiEdits.contains(name)) return _edit(rest, output);
  if (_geminiReads.contains(name)) return ActivityEntry(ActivityKind.read, rest, detail: output);
  if (_geminiSearches.contains(name)) {
    return ActivityEntry(ActivityKind.search, rest, detail: output);
  }
  return ActivityEntry(ActivityKind.other, _withoutGlyph(head), detail: output);
}

CommandEntry _command(String command, List<String> output, {CommandState? state}) => CommandEntry(
  command.trim(),
  output: output,
  state: state ?? (output.any(_failure.hasMatch) ? CommandState.failed : CommandState.unknown),
);

EditEntry _edit(String header, List<String> output) {
  final counts = _counts.firstMatch(header);
  final diff = <DiffRow>[];
  for (final line in output) {
    final row = _diffRow.firstMatch(line);
    if (row != null) {
      diff.add(DiffRow(row[1] == '+' ? DiffKind.added : DiffKind.removed, row[2]!));
      continue;
    }
    final context = _contextRow.firstMatch(line);
    if (context != null) diff.add(DiffRow(DiffKind.context, context[1]!));
  }
  int count(DiffKind kind) => diff.where((r) => r.kind == kind).length;
  return EditEntry(
    header.replaceFirst(_counts, '').trim(),
    added: counts != null ? int.parse(counts[1]!) : (diff.isEmpty ? null : count(DiffKind.added)),
    removed: counts != null
        ? int.parse(counts[2]!)
        : (diff.isEmpty ? null : count(DiffKind.removed)),
    diff: diff,
  );
}

/// [lines] without the `⎿` / `└` glyph, aligned to the first line's text.
List<String> _outputLines(List<String> lines) {
  if (lines.isEmpty) return const [];
  final first = lines.first;
  final glyph = _outputGlyph.firstMatch(first);
  final column = glyph?.end ?? _indent(first);
  return [
    for (final line in lines)
      if (_outputGlyph.hasMatch(line))
        line.replaceFirst(_outputGlyph, '')
      else
        line.substring(_indent(line) < column ? _indent(line) : column),
  ];
}

int _indent(String line) => line.length - line.trimLeft().length;

// Agent replies.
final _speaker = RegExp(r'^[⏺●•✦]\s+');
final _thinking = RegExp(r'^[✻✽✶✢∴]\s*(?:Thinking|Thought for)\b');
final _error = RegExp(r'^(?:API Error|Error|ERROR|error|Fatal|fatal)(?: \w+)?:');
final _bullet = RegExp(r'^\s*[-*•]\s+(.+)$');
final _numbered = RegExp(r'^\s*(\d+[.)])\s+(.+)$');
final _columns = RegExp(r'[│├└┌┐┘┬┴┼]');

String _withoutGlyph(String line) => line.replaceFirst(RegExp(r'^\S+\s+'), '');

AgentEntry _agentEntry(String text) {
  final lines = text.split('\n');
  final first = lines.first.trim().replaceFirst(_speaker, '');
  if (_thinking.hasMatch(first)) return ThinkingEntry(_withoutGlyph(first));
  if (_error.hasMatch(first)) {
    final rest = lines.skip(1).map((l) => l.trim()).join('\n').trim();
    return ErrorEntry(first, detail: rest.isEmpty ? null : rest);
  }
  final body = [lines.first.replaceFirst(_speaker, ''), ...lines.skip(1)];
  return MessageEntry(_segments(body));
}

List<MessageSegment> _segments(List<String> lines) {
  if (lines.first.trimLeft().startsWith('```')) {
    final code = lines.skip(1).where((l) => !l.trimLeft().startsWith('```'));
    return [MessageSegment(SegmentKind.preformatted, code.join('\n'))];
  }
  if (lines.any(_columns.hasMatch)) {
    return [MessageSegment(SegmentKind.preformatted, lines.join('\n'))];
  }
  final segments = <MessageSegment>[];
  void extend(String line) {
    final last = segments.removeLast();
    segments.add(MessageSegment(last.kind, '${last.text} ${line.trim()}', marker: last.marker));
  }

  for (final line in lines) {
    final bullet = _bullet.firstMatch(line);
    final numbered = _numbered.firstMatch(line);
    if (bullet != null) {
      segments.add(MessageSegment(SegmentKind.bullet, bullet[1]!.trim()));
    } else if (numbered != null) {
      segments.add(MessageSegment(SegmentKind.numbered, numbered[2]!.trim(), marker: numbered[1]));
    } else if (segments.isEmpty) {
      segments.add(MessageSegment(SegmentKind.paragraph, line.trim()));
    } else if (segments.last.kind == SegmentKind.paragraph || _indent(line) > 0) {
      extend(line);
    } else {
      segments.add(MessageSegment(SegmentKind.paragraph, line.trim()));
    }
  }
  return segments;
}
