/// Sticky Ctrl/Alt from the extra-keys bar applied to the next input.
library;

import 'extra_key.dart';

final class ModifierState {
  const ModifierState({
    this.ctrl = false,
    this.alt = false,
    this.ctrlLocked = false,
    this.altLocked = false,
  });

  final bool ctrl;
  final bool alt;
  final bool ctrlLocked;
  final bool altLocked;

  bool get any => ctrl || alt;

  ModifierState toggle(Modifier m) => switch (m) {
    Modifier.ctrl => ModifierState(ctrl: !ctrl, alt: alt, altLocked: altLocked),
    Modifier.alt => ModifierState(ctrl: ctrl, alt: !alt, ctrlLocked: ctrlLocked),
  };

  ModifierState lock(Modifier m) => switch (m) {
    Modifier.ctrl => ModifierState(ctrl: true, ctrlLocked: true, alt: alt, altLocked: altLocked),
    Modifier.alt => ModifierState(alt: true, altLocked: true, ctrl: ctrl, ctrlLocked: ctrlLocked),
  };

  /// Returns the bytes to send and the state for the following input.
  (String, ModifierState) apply(String input) {
    if (!any || input.isEmpty) return (input, this);
    var out = input;
    if (ctrl && input.length == 1) out = _ctrl(input);
    if (alt) out = '\x1b$out';
    return (
      out,
      ModifierState(ctrl: ctrlLocked, alt: altLocked, ctrlLocked: ctrlLocked, altLocked: altLocked),
    );
  }

  static String _ctrl(String ch) {
    final c = ch.codeUnitAt(0);
    if (ch == ' ') return '\x00';
    if (ch == '?') return '\x7f';
    if (c >= 0x61 && c <= 0x7a) return String.fromCharCode(c - 0x60);
    if (c >= 0x40 && c <= 0x5f) return String.fromCharCode(c & 0x1f);
    return ch;
  }
}
