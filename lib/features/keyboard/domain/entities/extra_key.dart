/// One key on the extra-keys bar: either bytes to send or a modifier.
library;

enum Modifier { ctrl, alt }

final class ExtraKey {
  const ExtraKey.send(this.label, String this.sequence) : modifier = null;
  const ExtraKey.modifier(this.label, Modifier this.modifier) : sequence = null;

  final String label;
  final String? sequence;
  final Modifier? modifier;
}
