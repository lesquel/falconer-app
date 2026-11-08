import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/hosts/domain/usecases/paired_devices.dart';
import 'package:openmosh/features/hosts/presentation/controllers/paired_devices_controller.dart';

import '../../support/fakes.dart';
import 'paired_devices_test.dart' show ScriptedAuth, device;

void main() {
  late FakeConnection conn;
  late ScriptedAuth auth;
  late ProviderContainer c;

  setUp(() async {
    final hosts = FakeHostRepository();
    await hosts.save(testHost(hookPath: '/h', deviceId: 'me1', hpk: 'k'));
    conn = FakeConnection(
      (_, s) => ok({
        'devices': [device('me1'), device('other', name: 'Tablet')],
      }),
    );
    auth = ScriptedAuth();
    final connections = HostConnections(
      hosts: hosts,
      vault: FakeVault(),
      connector: FakeConnector(() => conn),
    );
    c = ProviderContainer(
      overrides: [
        pairedDevicesProvider.overrideWithValue(
          PairedDevices(connections: connections, hosts: hosts, auth: auth),
        ),
      ],
    );
  });
  tearDown(() => c.dispose());

  int revokes() => conn.scripts.where((s) => s.contains("'revoke'")).length;

  test('revoke runs only after confirmation and user verification', () async {
    final sub = c.listen(pairedDevicesControllerProvider('h1'), (_, _) {});
    final ctrl = c.read(pairedDevicesControllerProvider('h1').notifier);
    await ctrl.load();
    final tablet = c.read(pairedDevicesControllerProvider('h1')).devices!.last;

    expect(await ctrl.revoke(tablet, confirm: (_) async => false), RevokeOutcome.cancelled);
    expect(auth.reasons, isEmpty);
    expect(revokes(), 0);

    auth.allow = false;
    expect(await ctrl.revoke(tablet, confirm: (_) async => true), RevokeOutcome.cancelled);
    expect(revokes(), 0);

    auth.allow = true;
    expect(await ctrl.revoke(tablet, confirm: (_) async => true), RevokeOutcome.revoked);
    expect(revokes(), 1);

    final me = c.read(pairedDevicesControllerProvider('h1')).devices!.first;
    expect(await ctrl.revoke(me, confirm: (_) async => true), RevokeOutcome.revokedThisPhone);
    sub.close();
  });
}
