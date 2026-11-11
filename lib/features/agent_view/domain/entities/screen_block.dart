/// Structured pieces of an agent's visible screen, as produced by
/// `parseAgentScreen`. The graphic agent view renders each block natively:
/// text as text, a [ChoiceBlock] as buttons, an [InputBlock] as a composer.
library;

/// What answering a [ChoiceOption] means, so the UI can color it.
enum ChoiceKind { allow, allowAlways, deny, other }

/// Who a [TextBlock] comes from: the agent's reply, the user's own prompt
/// (or a shell command), or a tool/command run and its output.
enum TextRole { agent, user, tool }

/// One block of a parsed agent screen.
sealed class ScreenBlock {
  const ScreenBlock();
}

/// Plain content: one paragraph of the screen, borders removed. [role] is
/// [TextRole.agent] unless the detector is sure; a user prompt's text comes
/// without its prompt glyph.
final class TextBlock extends ScreenBlock {
  const TextBlock(this.text, {this.role = TextRole.agent});

  final String text;
  final TextRole role;

  @override
  bool operator ==(Object other) => other is TextBlock && other.text == text && other.role == role;

  @override
  int get hashCode => Object.hash(text, role);

  @override
  String toString() => role == TextRole.agent
      ? 'TextBlock(${_quote(text)})'
      : 'TextBlock(${role.name}: ${_quote(text)})';
}

/// A permission or decision menu the agent is waiting on. [detail] is the
/// command or file the menu is about (Claude's command box, Codex's `$`
/// line), only when the detector is sure; the lines also stay as text.
final class ChoiceBlock extends ScreenBlock {
  const ChoiceBlock(this.question, this.options, {this.detail});

  final String question;
  final List<ChoiceOption> options;
  final String? detail;

  ChoiceBlock withDetail(String? detail) => ChoiceBlock(question, options, detail: detail);

  @override
  bool operator ==(Object other) =>
      other is ChoiceBlock &&
      other.question == question &&
      other.detail == detail &&
      _listEquals(other.options, options);

  @override
  int get hashCode => Object.hash(question, detail, Object.hashAll(options));

  @override
  String toString() => detail == null
      ? 'ChoiceBlock(${_quote(question)}, $options)'
      : 'ChoiceBlock(${_quote(question)}, $options, detail: ${_quote(detail!)})';
}

/// One answer of a [ChoiceBlock]. [keys] are pane key names (the hook's
/// `pane.keys` allowlist) that pick this option from the current screen.
final class ChoiceOption {
  const ChoiceOption(this.label, this.keys, this.selected, this.kind);

  final String label;
  final List<String> keys;
  final bool selected;
  final ChoiceKind kind;

  @override
  bool operator ==(Object other) =>
      other is ChoiceOption &&
      other.label == label &&
      other.selected == selected &&
      other.kind == kind &&
      _listEquals(other.keys, keys);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(keys), selected, kind);

  @override
  String toString() =>
      'ChoiceOption(${_quote(label)}, $keys, ${selected ? 'selected' : '-'}, ${kind.name})';
}

/// The agent's input line, with whatever the user already typed there.
final class InputBlock extends ScreenBlock {
  const InputBlock(this.draft);

  final String draft;

  @override
  bool operator ==(Object other) => other is InputBlock && other.draft == draft;

  @override
  int get hashCode => draft.hashCode;

  @override
  String toString() => 'InputBlock(${_quote(draft)})';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String _quote(String s) => '"${s.replaceAll('\n', r'\n')}"';
