/// Commands of the `openmosh-hook` CLI that the app runs over SSH exec.
/// Arguments are built as argv and only turned into a shell string by
/// [HookCommand.toShell], which single-quotes every word.
library;

import 'dart:convert';

import '../../domain/failure.dart';
import '../../domain/posix_shell.dart';

enum RespondAction { allow, deny, text }

const maxRespondTextBytes = 4096;

/// Longest long-poll the hook accepts; it stays under the 30 s exec timeout.
const maxHerdrWaitMs = 20000;

final _herdrTarget = RegExp(r'^[A-Za-z0-9:_-]{1,64}$');
final _herdrPane = RegExp(r'^[A-Za-z0-9:%._@$-]{1,64}$');
final _herdrSession = RegExp(r'^[A-Za-z0-9._-]{1,64}$');
final _herdrRev = RegExp(r'^[0-9a-f]{16}$');

/// Herdr workspace and tab ids, as the hook validates them.
bool isHerdrTargetId(String id) => _herdrTarget.hasMatch(id);

/// Herdr pane ids (`w1:p2`), as the hook validates them.
bool isHerdrPaneId(String id) => !id.startsWith('-') && _herdrPane.hasMatch(id);

/// Herdr session names the hook accepts for `--session`.
bool isHerdrSessionName(String s) =>
    !s.startsWith('-') && s != '.' && s != '..' && _herdrSession.hasMatch(s);

/// A long-poll revision: 16 lowercase hex digits.
bool isHerdrRev(String s) => _herdrRev.hasMatch(s);

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

  factory HookCommand.devicesList() => const HookCommand._(['devices', 'list', '--json']);

  /// Removes the device's `authorized_keys` line and its push key (SEC-11).
  factory HookCommand.devicesRevoke(String deviceId) {
    _checkId(deviceId);
    return HookCommand._(['devices', 'revoke', deviceId, '--json']);
  }

  /// Token usage per agent over the last [days] days (1..31), read by the
  /// hook from the agents' local logs.
  factory HookCommand.usage({int days = 7}) {
    if (days < 1 || days > 31) throw const ValidationFailure('The period must be 1–31 days.');
    return HookCommand._(['usage', '--days', '$days', '--json']);
  }

  /// The hook's version and wire protocols (`protocol.herdr` gates the
  /// Herdr navigator).
  factory HookCommand.version() => const HookCommand._(['version', '--json']);

  /// Herdr workspaces, tabs and panes. With [since], the hook answers when the
  /// state's `rev` differs from it or after [waitMs] (a long-poll).
  factory HookCommand.herdrSnapshot({String? session, String? since, int waitMs = 0}) =>
      HookCommand._(['herdr', 'snapshot', ..._herdrPoll(session, since, waitMs), '--json']);

  /// One pane's visible text; long-polls like [HookCommand.herdrSnapshot].
  factory HookCommand.herdrRead(
    String paneId, {
    String? session,
    String? since,
    int waitMs = 0,
    int? lines,
  }) {
    if (!isHerdrPaneId(paneId)) throw const ValidationFailure('Invalid identifier.');
    if (lines != null && (lines < 1 || lines > 400)) {
      throw const ValidationFailure('Invalid identifier.');
    }
    return HookCommand._([
      'herdr',
      'read',
      '--pane',
      paneId,
      ..._herdrPoll(session, since, waitMs),
      if (lines != null) ...['--lines', '$lines'],
      '--json',
    ]);
  }

  /// One allowlisted Herdr action; its `{"op":…}` body goes on stdin.
  factory HookCommand.herdrAction({String? session}) =>
      HookCommand._(['herdr', 'action', ..._herdrPoll(session, null, 0), '--json']);

  static List<String> _herdrPoll(String? session, String? since, int waitMs) {
    if (session != null && !isHerdrSessionName(session)) {
      throw const ValidationFailure('Invalid identifier.');
    }
    if (since != null && !isHerdrRev(since)) throw const ValidationFailure('Invalid identifier.');
    if (waitMs < 0 || waitMs > maxHerdrWaitMs) {
      throw const ValidationFailure('Invalid identifier.');
    }
    return [
      if (session != null) ...['--session', session],
      if (since != null) ...['--since', since],
      if (since != null && waitMs > 0) ...['--wait-ms', '$waitMs'],
    ];
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
