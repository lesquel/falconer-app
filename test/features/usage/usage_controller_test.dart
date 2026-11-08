import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/usage/domain/usecases/load_agent_usage.dart';
import 'package:openmosh/features/usage/presentation/controllers/usage_controller.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ssh/domain/ssh_ports.dart';

import '../../support/fakes.dart';

/// Each hook call waits for the test to answer it, in any order.
class GatedConnection extends FakeConnection {
  GatedConnection() : super((_, _) => ok(null));
  final calls = <(String, Completer<ExecOutput>)>[];

  @override
  Future<ExecOutput> exec(String command, {List<int>? stdin}) {
    final c = Completer<ExecOutput>();
    calls.add((utf8.decode(stdin ?? const []), c));
    return c.future;
  }

  void reply(int i, Object? data) => calls[i].$2.complete(ok(data));
}

void main() {
  late GatedConnection conn;
  late ProviderContainer c;
  setUp(() async {
    final hosts = FakeHostRepository();
    await hosts.save(testHost(hookPath: '/h'));
    conn = GatedConnection();
    final connections = HostConnections(
      hosts: hosts,
      vault: FakeVault(),
      connector: FakeConnector(() => conn),
    );
    c = ProviderContainer(
      overrides: [loadAgentUsageProvider.overrideWithValue(LoadAgentUsage(connections))],
    );
  });

  /// Waits until [n] hook calls reached the connection.
  Future<void> calls(int n) async {
    while (conn.calls.length < n) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  tearDown(() => c.dispose());

  UsageState state() => c.read(usageControllerProvider('h1'));
  UsageController ctrl() => c.read(usageControllerProvider('h1').notifier);

  test('loads 7 days by default and keeps the report', () async {
    final sub = c.listen(usageControllerProvider('h1'), (_, _) {});
    addTearDown(sub.close);
    final f = ctrl().load();
    expect(state().loading, isTrue);
    await calls(1);
    conn.reply(0, {'days': 7, 'agents': []});
    await f;
    expect(conn.calls.single.$1, contains("'--days' '7'"));
    expect(state().report?.days, 7);
    expect(state().loading, isFalse);
  });

  test('a slower earlier reply never overwrites the newer period', () async {
    final sub = c.listen(usageControllerProvider('h1'), (_, _) {});
    addTearDown(sub.close);
    final first = ctrl().load();
    await calls(1);
    final second = ctrl().setDays(30);
    expect(state().days, 30);
    await calls(2);
    expect(conn.calls[1].$1, contains("'--days' '30'"));
    conn.reply(1, {'days': 30, 'agents': []});
    await second;
    conn.reply(0, {'days': 7, 'agents': []});
    await first;
    expect(state().report?.days, 30);
    expect(state().days, 30);
  });

  test('errors keep the previous report', () async {
    final sub = c.listen(usageControllerProvider('h1'), (_, _) {});
    addTearDown(sub.close);
    final f = ctrl().load();
    await calls(1);
    conn.reply(0, {'days': 7, 'agents': []});
    await f;
    final g = ctrl().load();
    await calls(2);
    conn.calls[1].$2.complete(
      text(
        jsonEncode({
          'ok': false,
          'error': {'code': 'io', 'message': 'disk full'},
        }),
        code: 1,
      ),
    );
    await g;
    expect(state().error, isA<HookFailure>());
    expect(state().report?.days, 7);
  });
}
