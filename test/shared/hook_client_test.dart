import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/hook/domain/hook_client.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';

import '../support/fakes.dart';

void main() {
  const hook = '/home/me/.local/bin/openmosh-hook';
  const client = HookClient();

  test('the login shell only sees `sh -s`; the quoted argv goes on stdin', () async {
    final conn = FakeConnection((_, _) => ok([]));
    await client.call(conn, hook, HookCommand.sessionsList());
    expect(conn.commands.single, 'sh -s');
    expect(conn.scripts.single, "'$hook' 'sessions' 'list' '--json'\n");
  });

  test('hostile text stays one quoted word inside the script', () async {
    final conn = FakeConnection((_, _) => ok(null));
    await client.call(
      conn,
      hook,
      HookCommand.respond('ev1', RespondAction.text, text: "it's \$(id) `x`; fish"),
    );
    expect(conn.commands.single, 'sh -s');
    expect(
      conn.scripts.single,
      "'$hook' 'respond' 'ev1' '--action' 'text' '--text' "
      "'it'\\''s \$(id) `x`; fish' '--json'\n",
    );
  });

  test('pair-ssh request JSON is piped to the hook from a quoted printf', () async {
    final conn = FakeConnection((_, _) => ok({'device_id': 'd'}));
    final json = jsonEncode({'name': "Bob's phone", 'endpoint': r'https://x/$(id)'});
    await client.call(conn, hook, HookCommand.pairSsh(), stdin: utf8.encode(json));
    expect(conn.commands.single, 'sh -s');
    expect(
      conn.scripts.single,
      "printf '%s' '{\"name\":\"Bob'\\''s phone\",\"endpoint\":\"https://x/\$(id)\"}' "
      "| '$hook' 'pair-ssh' '--json'\n",
    );
  });

  test('hook path resolution also runs through `sh -s`', () async {
    final conn = FakeConnection((_, _) => text('/usr/bin/openmosh-hook\n'));
    expect(await client.resolvePath(conn), '/usr/bin/openmosh-hook');
    expect(conn.commands.single, 'sh -s');
    expect(conn.scripts.single, '${HookCommand.resolvePathScript}\n');
  });

  test('a missing hook (exit 127) is still reported as hook_missing', () async {
    final conn = FakeConnection((_, _) => text('', code: 127));
    await expectLater(
      client.call(conn, hook, HookCommand.sessionsList()),
      throwsA(predicate((e) => '$e'.contains('not installed'))),
    );
  });
}
