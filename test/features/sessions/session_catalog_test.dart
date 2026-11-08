import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/sessions/domain/entities/remote_session.dart';
import 'package:openmosh/features/sessions/domain/usecases/session_catalog.dart';

import '../../support/fakes.dart';

void main() {
  late FakeHostRepository hosts;
  setUp(() async {
    hosts = FakeHostRepository();
    await hosts.save(testHost(hookPath: '/h'));
  });

  SessionCatalog catalog(Object? data) => SessionCatalog(HostConnections(
      hosts: hosts, vault: FakeVault(), connector: FakeConnector(() => FakeConnection((_, _) => ok(data)))));

  test('parses sessions and builds quoted attach commands', () async {
    final list = await catalog([
      {'name': 'main', 'kind': 'herdr', 'attached': true},
      {'name': 'work', 'kind': 'tmux', 'windows': 3},
      {'name': 'bad name; rm', 'kind': 'tmux'},
      {'name': 'x', 'kind': 'screen'},
    ]).sessions('h1');
    expect(list.map((s) => s.name), ['main', 'work']);
    expect(list[0].attachCommand, "'herdr' 'session' 'attach' 'main'");
    expect(list[1].attachCommand, "'tmux' 'new-session' '-A' '-s' 'work'");
    expect(list[1].windows, 3);
  });

  test('parses the hook sessions report shape', () async {
    final list = await catalog({
      'sessions': [
        {'name': 'main', 'runtime': 'herdr', 'running': true, 'default': true, 'attached': null},
        {'name': 'dev', 'runtime': 'tmux', 'running': true, 'default': false, 'attached': true},
      ],
      'unavailable': ['tmux'],
    }).sessions('h1');
    expect(list.map((s) => (s.name, s.kind, s.attached)),
        [('main', SessionKind.herdr, false), ('dev', SessionKind.tmux, true)]);
  });

  test('parses the hook agents report shape', () async {
    final list = await catalog({
      'agents': [
        {'pane_id': 'w7:pA', 'agent': 'claude', 'status': 'blocked', 'state_change_seq': 3,
         'cwd': '/src', 'title': 'Allow Bash?', 'workspace_id': null, 'runtime': 'herdr'},
      ],
      'unavailable': [],
    }).agents('h1');
    expect(list.single.state, AgentState.blocked);
    expect(list.single.title, 'Allow Bash?');
  });

  test('parses Herdr agents', () async {
    final list = await catalog({
      'agents': [
        {'pane_id': 'w1:p2', 'agent': 'claude', 'agent_status': 'blocked', 'terminal_title_stripped': 'Allow edit?'},
        {'pane_id': 'w1:p3', 'agent': 'codex', 'agent_status': 'weird'},
        {'agent': 'no-pane'},
      ]
    }).agents('h1');
    expect(list.length, 2);
    expect(list[0].state, AgentState.blocked);
    expect(list[0].title, 'Allow edit?');
    expect(list[1].state, AgentState.unknown);
  });
}
