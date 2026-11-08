/// Cleaning of text pasted into the remote terminal.
library;

/// ESC, every C0 control except tab, line feed and carriage return, and every
/// C1 control (U+0080–U+009F, which includes the 8-bit CSI U+009B).
final _unsafe = RegExp('[\\x00-\\x08\\x0B\\x0C\\x0E-\\x1F\\x80-\\x9F]');

/// Removes the characters a paste could use to end bracketed paste early
/// (`ESC[201~`, `CSI 201~`) or to inject other control sequences. With ESC
/// and CSI gone no end marker can be rebuilt, so one pass is enough.
String sanitizePaste(String text) => text.replaceAll(_unsafe, '');

/// [text] as a paste: sanitized, and wrapped in bracketed-paste markers when
/// the remote app enabled them.
String wrapPaste(String text, {required bool bracketed}) {
  final clean = sanitizePaste(text);
  return bracketed ? '\x1b[200~$clean\x1b[201~' : clean;
}
