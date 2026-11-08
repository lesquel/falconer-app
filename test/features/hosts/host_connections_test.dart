import 'dart:convert';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/entities/host_draft.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/hosts/domain/usecases/manage_hosts.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';
import 'package:openmosh/shared/ssh/data/datasources/ssh_bridge.dart';

import '../../support/fakes.dart';

void main() {
  late FakeHostRepository repo;
  late FakeVault vault;
  late FakeConnector connector;
  late FakeConnection conn;
  late HostConnections pool;

  setUp(() async {
    repo = FakeHostRepository();
    await repo.save(testHost());
    vault = FakeVault();
    conn = FakeConnection(
      (_, stdin) => utf8.decode(stdin!).startsWith('command -v')
          ? text('/home/me/.local/bin/openmosh-hook\n')
          : ok(const []),
    );
    connector = FakeConnector(() => conn);
    pool = HostConnections(hosts: repo, vault: vault, connector: connector);
  });

  test('every new connection requires unlocking the key; live ones are reused', () async {
    await pool.connection('h1');
    await pool.connection('h1');
    expect(vault.unlocks, 1);
    conn.closed = true;
    conn = FakeConnection((_, _) => ok(null));
    await pool.connection('h1');
    expect(vault.unlocks, 2);
  });

  test('unlocking the key counts as a verification; a cancelled unlock does not', () async {
    var verified = 0;
    vault.cancel = true;
    pool = HostConnections(
      hosts: repo,
      vault: vault,
      connector: connector,
      onVerified: () => verified++,
    );
    await expectLater(pool.connection('h1'), throwsA(isA<UserCancelledFailure>()));
    expect(verified, 0);
    vault.cancel = false;
    await pool.connection('h1');
    expect(verified, 1);
  });

  test('connects with the pinned fingerprint of the host', () async {
    await pool.connection('h1');
    expect(connector.endpoints.single.pinnedFingerprint, testHost().fingerprint);
  });

  test('cancelled unlock never reaches the network', () async {
    vault.cancel = true;
    await expectLater(pool.connection('h1'), throwsA(isA<UserCancelledFailure>()));
    expect(connector.endpoints, isEmpty);
  });

  test('host key mismatch from the core is surfaced as non-overridable', () async {
    final failure = mapCoreError(
      AnyhowException('host_key_mismatch: expected SHA256:aaa got SHA256:bbb'),
    );
    expect(failure, isA<HostKeyMismatchFailure>());
    final m = failure as HostKeyMismatchFailure;
    expect(m.overridable, isFalse);
    expect(m.expected, 'SHA256:aaa');
    expect(m.actual, 'SHA256:bbb');

    connector.fail = failure;
    await expectLater(pool.connection('h1'), throwsA(isA<HostKeyMismatchFailure>()));
    expect(pool.isConnected('h1'), isFalse);
  });

  test('hook path is resolved once, saved, and quoted in every call', () async {
    await pool.runHook('h1', HookCommand.sessionsList());
    await pool.runHook('h1', HookCommand.agentsList());
    expect(conn.scripts.where((c) => c.startsWith('command -v')).length, 1);
    expect(conn.commands.toSet(), {'sh -s'});
    expect((await repo.byId('h1'))!.hookPath, '/home/me/.local/bin/openmosh-hook');
    expect(conn.scripts.last, "'/home/me/.local/bin/openmosh-hook' 'agents' 'list' '--json'\n");
  });

  test('a host without the hook binary reports hook_missing', () async {
    conn = FakeConnection((_, _) => text('', code: 1));
    await expectLater(
      pool.runHook('h1', HookCommand.sessionsList()),
      throwsA(isA<HookFailure>().having((e) => e.code, 'code', 'hook_missing')),
    );
  });

  group('ManageHosts', () {
    late ManageHosts manage;
    setUp(
      () =>
          manage = ManageHosts(repo, connector, newId: () => 'new', now: () => DateTime.utc(2026)),
    );

    const draft = HostDraft(alias: 'pi', address: 'pi.tail1.ts.net', port: 22, user: 'pi');

    test('adding requires a well-formed confirmed fingerprint', () async {
      await expectLater(
        manage.addConfirmed(draft, confirmedFingerprint: 'yes'),
        throwsA(isA<ValidationFailure>()),
      );
      final h = await manage.addConfirmed(draft, confirmedFingerprint: await manage.probe(draft));
      expect(h.fingerprint, connector.probe);
    });

    test('invalid drafts are rejected', () {
      for (final d in const [
        HostDraft(alias: '', address: 'a', port: 22, user: 'u'),
        HostDraft(alias: 'a', address: 'bad host', port: 22, user: 'u'),
        HostDraft(alias: 'a', address: 'h', port: 0, user: 'u'),
        HostDraft(alias: 'a', address: 'h', port: 22, user: 'u;id'),
        HostDraft(alias: 'a', address: '999.1.1.1', port: 22, user: 'u'),
        HostDraft(alias: 'a', address: '100.064.0.1', port: 22, user: 'u'),
      ]) {
        expect(() => d.validated(), throwsA(isA<ValidationFailure>()));
      }
    });

    test('dotted-quad and host-name addresses still validate', () {
      for (final a in ['100.64.0.1', '192.168.1.10', 'pi.tail1.ts.net', 'fe80::1']) {
        expect(HostDraft(alias: 'a', address: a, port: 22, user: 'u').validated().address, a);
      }
    });

    test('editing cannot move the pin to another address', () async {
      final h = await manage.addConfirmed(draft, confirmedFingerprint: connector.probe);
      await expectLater(
        manage.edit(h, const HostDraft(alias: 'pi', address: 'evil.example', port: 22, user: 'pi')),
        throwsA(isA<ValidationFailure>()),
      );
      final renamed = await manage.edit(
        h,
        const HostDraft(alias: 'pi4', address: 'pi.tail1.ts.net', port: 22, user: 'pi'),
      );
      expect(renamed.alias, 'pi4');
      expect(renamed.fingerprint, h.fingerprint);
    });
  });
}
