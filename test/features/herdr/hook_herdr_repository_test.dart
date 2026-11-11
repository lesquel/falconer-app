import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/herdr/data/repositories/hook_herdr_repository.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ssh/domain/ssh_ports.dart';

import '../../support/fakes.dart';

const rev = '0123456789abcdef';

Map<String, Object?> snapshotJson() => {
  'rev': rev,
  'unchanged': false,
  'workspaces': [
    {'id': 'w1', 'label': 'api', 'focused': true},
    {'id': 'bad id', 'label': 'dropped', 'focused': false},
  ],
  'tabs': [
    {
      'id': 'w1:t1',
      'workspace_id': 'w1',
      'label': 'main',
      'number': 1,
      'agent_status': 'blocked',
      'pane_count': 2,
      'focused': true,
    },
  ],
  'panes': [
    {
      'id': 'w1:p1',
      'tab_id': 'w1:t1',
      'workspace_id': 'w1',
      'agent': 'claude',
      'agent_status': 'blocked',
      'focused': true,
    },
    {
      'id': 'w1:p2',
      'tab_id': 'w1:t1',
      'workspace_id': 'w1',
      'agent': null,
      'agent_status': 'sleeping',
      'focused': false,
    },
  ],
};

ExecOutput err(String code, String message) => text(
  jsonEncode({
    'ok': false,
    'error': {'code': code, 'message': message},
  }),
  code: 1,
);

void main() {
  late FakeHostRepository hosts;
  late FakeConnection conn;
  setUp(() async {
    hosts = FakeHostRepository();
    await hosts.save(testHost(hookPath: '/h'));
  });

  HookHerdrRepository repo(ExecOutput Function(String script) reply) {
    conn = FakeConnection((_, stdin) => reply(utf8.decode(stdin!)));
    return HookHerdrRepository(
      HostConnections(hosts: hosts, vault: FakeVault(), connector: FakeConnector(() => conn)),
    );
  }

  test('parses a snapshot; unknown statuses become unknown, bad ids are dropped', () async {
    final r = await repo((_) => ok(snapshotJson())).snapshot('h1', session: 'default');
    expect(conn.scripts.single, "'/h' 'herdr' 'snapshot' '--session' 'default' '--json'\n");
    expect(r.rev, rev);
    expect(r.unchanged, isFalse);
    final s = r.body!;
    expect(s.workspaces.map((w) => w.id), ['w1']);
    expect(s.workspaces.single.focused, isTrue);
    expect(s.tabs.single.status, HerdrStatus.blocked);
    expect(s.tabs.single.paneCount, 2);
    expect(s.panes.map((p) => p.status), [HerdrStatus.blocked, HerdrStatus.unknown]);
    expect(s.panes.last.agent, isNull);
    expect(s.tabsOf('w1').single.label, 'main');
    expect(s.panesOf('w1:t1').length, 2);
    expect(s.focusedPane?.id, 'w1:p1');
  });

  test('an unchanged answer carries only the revision', () async {
    final r = await repo((_) => ok({'rev': rev, 'unchanged': true}))
        .snapshot('h1', since: rev, waitMs: 15000);
    expect(conn.scripts.single, contains("'--since' '$rev' '--wait-ms' '15000'"));
    expect(r.unchanged, isTrue);
    expect(r.body, isNull);
  });

  test('a malformed revision is a protocol error', () async {
    final f = repo((_) => ok({'rev': "x'; rm", 'unchanged': true})).snapshot('h1');
    await expectLater(f, throwsA(isA<HookFailure>().having((e) => e.code, 'code', 'protocol')));
  });

  test('reads a pane screen without control characters', () async {
    final r = await repo(
      (_) => ok({
        'rev': rev,
        'unchanged': false,
        'agent': 'codex',
        'agent_status': 'working',
        'lines': ['  hello\u202e', '│ Allow? │'],
      }),
    ).read('h1', 'w1:p1');
    expect(conn.scripts.single, "'/h' 'herdr' 'read' '--pane' 'w1:p1' '--json'\n");
    expect(r.body!.agent, 'codex');
    expect(r.body!.status, HerdrStatus.working);
    expect(r.body!.lines, ['  hello', '│ Allow? │']);
  });

  test('actions send the JSON body on stdin and return the new id', () async {
    final id = await repo((_) => ok({'op': 'workspace.create', 'id': 'w3'}))
        .act('h1', HerdrAction.workspaceCreate('new'), session: 'default');
    expect(id, 'w3');
    expect(
      conn.scripts.single,
      "printf '%s' '{\"op\":\"workspace.create\",\"label\":\"new\"}' | "
      "'/h' 'herdr' 'action' '--session' 'default' '--json'\n",
    );
  });

  test('maps hook error codes to Herdr failures', () async {
    Future<void> expectCode(ExecOutput reply, String code, String message) => expectLater(
      repo((_) => reply).snapshot('h1'),
      throwsA(
        isA<HookFailure>()
            .having((e) => e.code, 'code', code)
            .having((e) => e.message, 'message', message),
      ),
    );
    await expectCode(err('invalid_request', 'id not in snapshot'), 'invalid_request', herdrInvalid);
    await expectCode(
      err('runtime_unavailable', 'no socket'),
      'runtime_unavailable',
      herdrNotRunning,
    );
    await expectCode(
      err('runtime_error', 'herdr refused the request: x'),
      'runtime_error',
      herdrRefused,
    );
    await expectCode(text('', code: 2), 'hook_outdated', herdrHookOutdated);
  });

  test('capability needs protocol herdr >= 1 and is cached once true', () async {
    var replies = 0;
    final yes = repo((_) {
      replies++;
      return ok({
        'version': '0.3.0',
        'protocol': {'pair': 1, 'push': 1, 'herdr': 1},
      });
    });
    expect(await yes.supportsHerdr('h1'), isTrue);
    expect(await yes.supportsHerdr('h1'), isTrue);
    expect(replies, 1);
    expect(conn.scripts.single, "'/h' 'version' '--json'\n");

    final old = repo(
      (_) => ok({
        'version': '0.2.0',
        'protocol': {'pair': 1, 'push': 1},
      }),
    );
    expect(await old.supportsHerdr('h1'), isFalse);
    expect(await repo((_) => text('', code: 2)).supportsHerdr('h1'), isFalse);
  });
}
