/// What one paragraph of an agent's screen is, so the graphic view can draw
/// a command, a file edit and a reply differently. Derived from a
/// `TextBlock` by `entryFor`.
library;

/// One readable item of the conversation.
sealed class AgentEntry {
  const AgentEntry();
}

/// The user's own prompt, exactly as written.
final class UserEntry extends AgentEntry {
  const UserEntry(this.text);
  final String text;
}

/// A reply of the agent, split into paragraphs, list items and code.
final class MessageEntry extends AgentEntry {
  const MessageEntry(this.segments);
  final List<MessageSegment> segments;
}

enum SegmentKind { paragraph, bullet, numbered, preformatted }

/// One piece of a reply. [marker] is the number of a numbered item (`1.`).
final class MessageSegment {
  const MessageSegment(this.kind, this.text, {this.marker});

  final SegmentKind kind;
  final String text;
  final String? marker;

  @override
  bool operator ==(Object other) =>
      other is MessageSegment && other.kind == kind && other.text == text && other.marker == marker;

  @override
  int get hashCode => Object.hash(kind, text, marker);

  @override
  String toString() => 'MessageSegment(${kind.name}, "$text")';
}

/// Only what the agent's screen proves. A finished-tool mark is no proof of
/// success (it does not reflect the exit code), so success is never claimed.
enum CommandState { unknown, running, failed }

/// A shell command the agent ran, with its output.
final class CommandEntry extends AgentEntry {
  const CommandEntry(this.command, {this.output = const [], this.state = CommandState.unknown});

  final String command;
  final List<String> output;
  final CommandState state;
}

enum DiffKind { context, added, removed }

/// One row of a file diff.
final class DiffRow {
  const DiffRow(this.kind, this.text);
  final DiffKind kind;
  final String text;
}

/// A file the agent changed. The counts are null when the screen has none;
/// [notes] are the lines under it that are not diff rows.
final class EditEntry extends AgentEntry {
  const EditEntry(
    this.path, {
    this.added,
    this.removed,
    this.diff = const [],
    this.notes = const [],
    this.failed = false,
  });

  final String path;
  final int? added;
  final int? removed;
  final List<DiffRow> diff;
  final List<String> notes;
  final bool failed;
}

enum ActivityKind { read, search, other }

/// A quiet tool step: reading a file, searching, calling a tool.
final class ActivityEntry extends AgentEntry {
  const ActivityEntry(this.kind, this.label, {this.detail = const [], this.failed = false});

  final ActivityKind kind;
  final String label;
  final List<String> detail;
  final bool failed;
}

/// Output with no command on screen (a plain shell).
final class OutputEntry extends AgentEntry {
  const OutputEntry(this.lines);
  final List<String> lines;
}

/// The agent's "thinking" status line.
final class ThinkingEntry extends AgentEntry {
  const ThinkingEntry(this.text);
  final String text;
}

/// An error the agent reported.
final class ErrorEntry extends AgentEntry {
  const ErrorEntry(this.title, {this.detail});

  final String title;
  final String? detail;
}
