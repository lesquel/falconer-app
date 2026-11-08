import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/entities/paired_device.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/hosts/domain/usecases/paired_devices.dart';
import 'package:openmosh/features/keys/domain/repositories/key_vault.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';

import '../../support/fakes.dart';

class ScriptedAuth implements UserAuthenticator {
  bool allow = true;
  final reasons = <String>[];
  @override
  Future<bool> authenticate(String reason) async {
    reasons.add(reason);
    return allow;
  }
}

Map<String, Object?> device(String id, {String name = 'Pixel', bool stale = false}) => {
  'id': id,
  'name': name,
  'paired_at': 1762560000,
  'endpoint': 'https://ntfy.example/up1',
  'endpoint_stale': stale,
  'ssh_authorized': true,
};

void main() {
  late FakeHostRepository hosts;
  late FakeConnection conn;
  late ScriptedAuth auth;
  late PairedDevices devices;

  setUp(() async {
    hosts = FakeHostRepository();
    await hosts.save(testHost(hookPath: '/h', deviceId: 'me1', hpk: 'k'));
    conn = FakeConnection((_, s) {
      final script = utf8.decode(s ?? const []);
      if (script.contains("'revoke'")) return ok({'revoked': device('other')});
      return ok({
        'devices': [device('me1'), device('other', name: 'Tablet', stale: true), 'junk'],
      });
    });
    auth = ScriptedAuth();
    devices = PairedDevices(
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
      hosts: hosts,
      auth: auth,
    );
  });

  test('devices commands are argv with --json', () {
    expect(HookCommand.devicesList().argv, ['devices', 'list', '--json']);
    expect(HookCommand.devicesRevoke('-a1').argv, ['devices', 'revoke', '-a1', '--json']);
    expect(() => HookCommand.devicesRevoke(''), throwsA(isA<ValidationFailure>()));
  });

  test('list maps the hook shape and marks this phone', () async {
    final list = await devices.list('h1');
    expect(conn.scripts.single, "'/h' 'devices' 'list' '--json'\n");
    expect(list.map((d) => d.id), ['me1', 'other']);
    expect(list.first.isThisPhone, isTrue);
    expect(list.last.isThisPhone, isFalse);
    expect(list.last.name, 'Tablet');
    expect(list.last.endpointStale, isTrue);
    expect(list.last.pairedAt, DateTime.fromMillisecondsSinceEpoch(1762560000 * 1000, isUtc: true));
  });

  test('a device with a bad field is skipped, never thrown', () {
    expect(PairedDevice.fromJson({'id': 7}, thisDeviceId: null), isNull);
    expect(PairedDevice.fromJson(device('x')..['paired_at'] = 'now', thisDeviceId: null), isNull);
    expect(PairedDevice.fromJson(device('x\u0007'), thisDeviceId: null), isNull);
  });

  test('revoke needs user verification and runs nothing when it is refused', () async {
    final other = (await devices.list('h1')).last;
    conn.scripts.clear();
    conn.stdins.clear();
    auth.allow = false;
    await expectLater(devices.revoke('h1', other), throwsA(isA<UserCancelledFailure>()));
    expect(conn.scripts, isEmpty);
    auth.allow = true;
    expect(await devices.revoke('h1', other), isFalse);
    expect(auth.reasons.last, contains('Tablet'));
    expect(conn.scripts.single, "'/h' 'devices' 'revoke' 'other' '--json'\n");
    expect(conn.closed, isFalse);
  });

  test('revoking this phone drops the connection and reports it', () async {
    final me = (await devices.list('h1')).first;
    expect(await devices.revoke('h1', me), isTrue);
    expect(conn.closed, isTrue);
  });

  test('device names from the host lose bidi and control characters; bad ids are dropped', () {
    final d = PairedDevice.fromJson({
      'id': 'd1',
      'name': 'Pix\u202Eel\u200B\x1b[2J',
      'paired_at': 1,
    }, thisDeviceId: null)!;
    expect(d.name, 'Pixel[2J');
    expect(
      PairedDevice.fromJson({'id': '../d', 'name': 'x', 'paired_at': 1}, thisDeviceId: null),
      isNull,
    );
  });
}
