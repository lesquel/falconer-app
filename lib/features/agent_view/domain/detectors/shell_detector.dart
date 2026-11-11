import '../entities/screen_block.dart';
import '../parsing/screen_line.dart';
import '../parsing/text_roles.dart';
import 'generic_detector.dart';

/// A plain shell (a pane without an agent): a command typed after a known
/// prompt shape is the user's, what follows it is the command's output.
/// Menus are found only as conservatively as for unknown agents.
final class ShellDetector extends GenericDetector {
  const ShellDetector();

  @override
  RoleStart? roleStart(ScreenLine line, TextRole? current) {
    if (line.indent != 0) return null;
    final command = shellCommand(line.text);
    return command == null ? null : userText(line, command);
  }

  @override
  TextRole get afterUser => TextRole.tool;

  @override
  bool get userIsOneLine => true;

  /// A bare prompt waits for the next command: nothing to show.
  @override
  bool isNoise(String trimmed) => _bare.any((p) => p.hasMatch(trimmed)) || super.isNoise(trimmed);
}

/// Prompt shapes: `user@host:~/dir$ `, `[user@host dir]$ `,
/// `user@host dir % `, `$ ` and `❯ `.
final _prompts = [
  RegExp(r'^[\w.-]+@[\w.-]+:\S*[$#] (\S.*)$'),
  RegExp(r'^\[[\w.-]+@[\w.-]+ [^\]]*\][$#] (\S.*)$'),
  RegExp(r'^[\w.-]+@[\w.-]+ \S+ [%#] (\S.*)$'),
  RegExp(r'^[$❯] (\S.*)$'),
];

final _bare = [
  RegExp(r'^[\w.-]+@[\w.-]+:\S*[$#]$'),
  RegExp(r'^\[[\w.-]+@[\w.-]+ [^\]]*\][$#]$'),
  RegExp(r'^[\w.-]+@[\w.-]+ \S+ [%#]$'),
  RegExp(r'^[$❯]$'),
];

/// The command typed after a shell prompt in [text], or null.
String? shellCommand(String text) {
  for (final p in _prompts) {
    final m = p.firstMatch(text);
    if (m != null) return m.group(1)!.trim();
  }
  return null;
}
