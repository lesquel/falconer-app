/// Commands of the `openmosh-hook` CLI that the app runs over SSH exec.
/// Arguments are built as argv and only turned into a shell string by
/// [HookCommand.toShell], which single-quotes every word.
library;

import 'dart:convert';

import '../../domain/failure.dart';
import '../../domain/posix_shell.dart';

enum RespondAction { allow, deny, text }

const maxRespondTextBytes = 4096;

final class HookCommand {
  const HookCommand._(this.argv);

  final List<String> argv;

  /// Run once at pairing; prints the absolute hook path.
  static const resolvePathScript =
      r'command -v openmosh-hook || echo "$HOME/.local/bin/openmosh-hook"';

  factory HookCommand.sessionsList() => const HookCommand._(['sessions', 'list', '--json']);

  factory HookCommand.agentsList() => const HookCommand._(['agents', 'list', '--json']);

  factory HookCommand.inboxList({int? since, int? limit}) => HookCommand._([
    'inbox',
    'list',
    '--json',
    if (since != null) ...['--since', '$since'],
    if (limit != null) ...['--limit', '$limit'],
  ]);

  factory HookCommand.respond(String eventId, RespondAction action, {String? text}) {
    _checkId(eventId);
    final args = ['respond', eventId, '--action', action.name];
    if (action == RespondAction.text) {
      final clean = sanitizeResponseText(text ?? '');
      if (clean.isEmpty) throw const ValidationFailure('Write a message first.');
      args.addAll(['--text', clean]);
    }
    args.add('--json');
    return HookCommand._(args);
  }

  /// Request JSON goes on stdin (TRD §6.4).
  factory HookCommand.pairSsh() => const HookCommand._(['pair-ssh', '--json']);

  factory HookCommand.setEndpoint(String deviceId, String url) {
    _checkId(deviceId);
    return HookCommand._(['devices', 'set-endpoint', deviceId, url, '--json']);
  }

  String toShell(String hookPath) => shJoin([hookPath, ...argv]);

  /// Script for [execCommand]: the quoted command line, with [stdin] piped in
  /// from a quoted `printf` (the script itself occupies the channel's stdin).
  /// [stdin] must be UTF-8 text without NUL (request JSON).
  String toScript(String hookPath, {List<int>? stdin}) {
    final line = toShell(hookPath);
    if (stdin == null) return '$line\n';
    return "printf '%s' ${shQuote(utf8.decode(stdin))} | $line\n";
  }

  /// The only command the remote login shell parses (it may be fish or csh):
  /// a POSIX `sh` reading the script from stdin.
  static const execCommand = 'sh -s';

  static void _checkId(String id) {
    // Hook ids are b64u and may start with '-'; the hook declares these
    // positionals with allow_hyphen_values, and quoting keeps them one word.
    if (id.isEmpty || id.length > 128 || id.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw const ValidationFailure('Invalid identifier.');
    }
  }
}

/// Mirrors the host-side rule (T-9): control characters stripped except
/// `\n`, at most 4 KiB of UTF-8.
String sanitizeResponseText(String text) {
  final clean = String.fromCharCodes(
    text.runes.where((r) => r == 0x0a || !(r < 0x20 || r == 0x7f || (r >= 0x80 && r < 0xa0))),
  );
  if (clean.codeUnits.isNotEmpty && _utf8Length(clean) > maxRespondTextBytes) {
    throw const ValidationFailure('Message is longer than 4 KiB.');
  }
  return clean;
}

int _utf8Length(String s) {
  var n = 0;
  for (final r in s.runes) {
    n += r < 0x80
        ? 1
        : r < 0x800
        ? 2
        : r < 0x10000
        ? 3
        : 4;
  }
  return n;
}
