import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';
import 'package:openmosh/shared/hook/domain/hook_envelope.dart';

void main() {
  const hook = '/home/me/.local/bin/openmosh-hook';

  group('HookCommand.usage', () {
    test('defaults to 7 days', () {
      expect(HookCommand.usage().argv, ['usage', '--days', '7', '--json']);
      expect(HookCommand.usage().toShell(hook), "'$hook' 'usage' '--days' '7' '--json'");
    });

    test('passes the period', () {
      expect(HookCommand.usage(days: 1).argv, ['usage', '--days', '1', '--json']);
      expect(HookCommand.usage(days: 30).argv, ['usage', '--days', '30', '--json']);
    });

    test('rejects a period outside 1..31', () {
      expect(() => HookCommand.usage(days: 0), throwsA(isA<ValidationFailure>()));
      expect(() => HookCommand.usage(days: 32), throwsA(isA<ValidationFailure>()));
    });
  });

  group('HookCommand.toShell', () {
    test('sessions list', () {
      expect(HookCommand.sessionsList().toShell(hook), "'$hook' 'sessions' 'list' '--json'");
    });

    test('inbox list with cursor', () {
      expect(HookCommand.inboxList(since: 41, limit: 100).argv, [
        'inbox',
        'list',
        '--json',
        '--since',
        '41',
        '--limit',
        '100',
      ]);
    });

    test('respond text quotes hostile input as one argument', () {
      final cmd = HookCommand.respond(
        'ev1',
        RespondAction.text,
        text: "it's \$(whoami) `id`\nnext",
      );
      expect(
        cmd.toShell(hook),
        "'$hook' 'respond' 'ev1' '--action' 'text' '--text' "
        "'it'\\''s \$(whoami) `id`\nnext' '--json'",
      );
    });

    test('respond allow has no --text', () {
      expect(HookCommand.respond('ev1', RespondAction.allow).argv, [
        'respond',
        'ev1',
        '--action',
        'allow',
        '--json',
      ]);
    });

    test('respond text strips control characters except newline and caps size', () {
      final cmd = HookCommand.respond('e', RespondAction.text, text: 'a\u001b[31mb\tc\nd');
      expect(cmd.argv[5], 'a[31mbc\nd');
      expect(
        () => HookCommand.respond('e', RespondAction.text, text: 'x' * 4097),
        throwsA(isA<ValidationFailure>()),
      );
      expect(() => HookCommand.respond('e', RespondAction.text), throwsA(isA<ValidationFailure>()));
    });

    test('empty or oversized ids are rejected; hyphen-leading ids are allowed', () {
      expect(() => HookCommand.respond('', RespondAction.allow), throwsA(isA<ValidationFailure>()));
      expect(
        () => HookCommand.respond('a' * 129, RespondAction.allow),
        throwsA(isA<ValidationFailure>()),
      );
      expect(HookCommand.respond('-AbC', RespondAction.allow).argv[1], '-AbC');
    });

    test('set-endpoint uses the JSON envelope', () {
      expect(HookCommand.setEndpoint('-d1', 'https://ntfy.sh/up').argv, [
        'devices',
        'set-endpoint',
        '-d1',
        'https://ntfy.sh/up',
        '--json',
      ]);
    });

    test('hook path resolution probe is a fixed command', () {
      expect(
        HookCommand.resolvePathScript,
        r'command -v openmosh-hook || echo "$HOME/.local/bin/openmosh-hook"',
      );
    });
  });

  group('parseHookEnvelope', () {
    test('returns data on ok', () {
      expect(parseHookEnvelope(utf8.encode('{"ok":true,"data":[1,2]}')), [1, 2]);
    });

    test('maps error envelope to HookFailure with code', () {
      Object? f() => parseHookEnvelope(
        utf8.encode('{"ok":false,"error":{"code":"not_found","message":"no such event"}}'),
      );
      expect(f, throwsA(isA<HookFailure>().having((e) => e.code, 'code', 'not_found')));
    });

    test('non-JSON output is a protocol error', () {
      expect(
        () => parseHookEnvelope(utf8.encode('bash: openmosh-hook: not found')),
        throwsA(isA<HookFailure>().having((e) => e.code, 'code', 'protocol')),
      );
    });
  });
}
