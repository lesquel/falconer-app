/// Builders for the user's saved shortcut keys.
library;

import '../../../../shared/domain/paste_text.dart';
import 'extra_key.dart';

abstract final class CustomKeys {
  /// `Ctrl+<letter>`; null unless [letter] is one ASCII letter.
  static ExtraKey? ctrl(String letter) {
    final l = letter.trim().toUpperCase();
    if (l.length != 1) return null;
    final c = l.codeUnitAt(0);
    if (c < 0x41 || c > 0x5a) return null;
    return ExtraKey.send('Ctrl+$l', String.fromCharCode(c - 0x40));
  }

  /// Text typed as is, optionally followed by Enter. The label defaults to the
  /// text, shortened to fit a key.
  /// Escape and control characters (pasted into the field) are dropped.
  static ExtraKey? text(String raw, {bool enter = false, String label = ''}) {
    final text = sanitizePaste(raw);
    if (text.isEmpty) return null;
    final name = label.trim().isNotEmpty
        ? label.trim()
        : (text.length > 12 ? '${text.substring(0, 11)}…' : text);
    return ExtraKey.send(name, enter ? '$text\r' : text);
  }
}
