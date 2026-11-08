import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/usage/domain/usecases/load_agent_usage.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ssh/domain/ssh_ports.dart';

import '../../support/fakes.dart';
import 'agent_usage_test.dart' show fixture;

void main() {
  late FakeHostRepository hosts;
  late FakeConnection conn;
  setUp(() async {
    hosts = FakeHostRepository();
    await hosts.save(testHost(hookPath: '/h'));
  });

  LoadAgentUsage usecase(ExecOutput Function() reply) {
    conn = FakeConnection((_, _) => reply());
    return LoadAgentUsage(
      HostConnections(hosts: hosts, vault: FakeVault(), connector: FakeConnector(() => conn)),
    );
  }

  test('runs `usage --days N --json` and parses the report', () async {
    final r = await usecase(() => ok(fixture()))('h1', days: 30);
    expect(conn.scripts.single, "'/h' 'usage' '--days' '30' '--json'\n");
    expect(r.agents.map((a) => a.agent), ['claude', 'codex', 'opencode']);
  });

  test('defaults to 7 days', () async {
    await usecase(() => ok(fixture()))('h1');
    expect(conn.scripts.single, contains("'--days' '7'"));
  });

  test('an older hook without `usage` asks to update the hook', () async {
    // clap rejects the unknown subcommand on stderr with exit code 2.
    final f = usecase(() => text('', code: 2))('h1');
    await expectLater(
      f,
      throwsA(
        isA<HookFailure>()
            .having((e) => e.code, 'code', 'hook_outdated')
            .having((e) => e.message, 'message', hookOutdatedForUsage),
      ),
    );
  });

  test('an unknown-command envelope also asks to update the hook', () async {
    final f = usecase(
      () => text(
        jsonEncode({
          'ok': false,
          'error': {'code': 'unknown_command', 'message': 'no such command'},
        }),
        code: 2,
      ),
    )('h1');
    await expectLater(
      f,
      throwsA(isA<HookFailure>().having((e) => e.code, 'code', 'hook_outdated')),
    );
  });

  test('other hook errors pass through', () async {
    final f = usecase(
      () => text(
        jsonEncode({
          'ok': false,
          'error': {'code': 'io', 'message': 'disk full'},
        }),
        code: 1,
      ),
    )('h1');
    await expectLater(f, throwsA(isA<HookFailure>().having((e) => e.code, 'code', 'io')));
  });
}
