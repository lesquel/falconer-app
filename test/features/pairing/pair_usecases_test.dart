import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/entities/host.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/inbox/domain/repositories/inbox_ports.dart';
import 'package:openmosh/features/pairing/domain/entities/pair_payload.dart';
import 'package:openmosh/features/pairing/domain/entities/pairing_messages.dart';
import 'package:openmosh/features/pairing/domain/repositories/pairing_gateway.dart';
import 'package:openmosh/features/pairing/domain/usecases/pair_usecases.dart';
import 'package:openmosh/shared/domain/b64u.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';

import '../../support/fakes.dart';

class FakeGateway implements PairingGateway {
  PairRequestBody? sent;
  PairPayload? code;
  @override
  Future<PairResponse> exchange(PairPayload code, PairRequestBody body) async {
    this.code = code;
    sent = body;
    return const PairResponse(
      deviceId: 'dev123',
      alias: 'workstation',
      sshUser: 'me',
      sshPort: 2222,
      sshFingerprint: 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM',
    );
  }
}

class FakeEndpoints implements PushEndpointSource {
  FakeEndpoints(this.url);
  String url;

  /// The distributor does not answer (ntfy asleep or missing).
  bool silent = false;
  @override
  Future<String> currentEndpoint() async {
    if (silent) {
      throw const PushFailure('The push distributor did not answer. Open ntfy and retry.');
    }
    return url;
  }

  @override
  Future<String?> knownEndpoint() async => url;
}

String code({String ip = '100.101.102.103'}) {
  final hpk = b64uEncode(List.filled(32, 7));
  final tok = b64uEncode(List.filled(16, 9));
  return 'openmosh://pair?v=3&i=$ip&k=$hpk&p=41000&t=$tok';
}

void main() {
  late FakeGateway gateway;
  late FakeHostRepository hosts;
  late FakeEndpoints endpoints;
  late PairWithQr pair;

  setUp(() {
    gateway = FakeGateway();
    hosts = FakeHostRepository();
    endpoints = FakeEndpoints('https://ntfy.sh/upXYZ');
    pair = PairWithQr(
      gateway: gateway,
      vault: FakeVault(),
      pushKeys: FakePushKeys(),
      endpoints: endpoints,
      hosts: hosts,
      newId: () => 'host-1',
      now: () => DateTime.fromMillisecondsSinceEpoch(1000 * 1000, isUtc: true),
    );
  });

  test('sends token, device ssh key, push key and endpoint; pins the host', () async {
    final host = await pair(code(), deviceName: 'Phone');
    final sent = gateway.sent!;
    expect(sent.token, List.filled(16, 9));
    expect(sent.sshPublicKey, 'ssh-ed25519 AAAAC3 device');
    expect(sent.pushPublicKey, List.filled(32, 3));
    expect(sent.endpoint, 'https://ntfy.sh/upXYZ');
    expect(sent.name, 'Phone');

    expect(host.fingerprint, 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM');
    expect(host.address, '100.101.102.103');
    expect(host.port, 2222);
    expect(host.user, 'me');
    expect(host.alias, 'workstation');
    expect(host.deviceId, 'dev123');
    expect(host.hostPushKey, b64uEncode(List.filled(32, 7)));
    expect(host.pairedVia, PairedVia.qr);
    expect(hosts.rows['host-1'], isNotNull);
  });

  test('invalid code makes no network call and saves nothing', () async {
    await expectLater(
      pair(code(ip: '192.168.1.2'), deviceName: 'Phone'),
      throwsA(isA<PairCodeFailure>()),
    );
    expect(gateway.sent, isNull);
    expect(hosts.rows, isEmpty);
  });

  test('a plain http push endpoint outside the tailnet is never sent', () async {
    endpoints.url = 'http://ntfy.example.com/up';
    final host = await pair(code(), deviceName: 'Phone');
    expect(gateway.sent!.endpoint, '');
    expect(host.pushEnabled, isFalse);
  });

  test(
    'without an answer from the push distributor the phone pairs without notifications',
    () async {
      endpoints.silent = true;
      final host = await pair(code(), deviceName: 'Phone');
      expect(gateway.sent!.endpoint, '');
      expect(host.paired, isTrue);
      expect(host.pushEnabled, isFalse);
      expect(hosts.rows.values.single.endpointSent, '');
    },
  );

  test('notifications are turned on later with devices set-endpoint', () async {
    await hosts.save(
      testHost(
        deviceId: 'd1',
        hpk: b64uEncode(List.filled(32, 1)),
        hookPath: '/h/openmosh-hook',
      ).copyWith(endpointSent: ''),
    );
    final conn = FakeConnection((cmd, _) => ok({'id': 'd1'}));
    final enable = EnablePush(
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
      hosts: hosts,
      endpoints: endpoints,
    );
    endpoints.silent = true;
    await expectLater(enable('h1'), throwsA(isA<PushFailure>()));
    expect((await hosts.byId('h1'))!.pushEnabled, isFalse);
    endpoints.silent = false;
    final host = await enable('h1');
    expect(conn.scripts.single, contains("'devices' 'set-endpoint' 'd1' 'https://ntfy.sh/upXYZ'"));
    expect(host.pushEnabled, isTrue);
    expect((await hosts.byId('h1'))!.endpointSent, 'https://ntfy.sh/upXYZ');
  });

  test('SSH pairing reply alias is cleaned; an oversized one is refused', () async {
    await hosts.save(testHost(hookPath: '/h/openmosh-hook'));
    var alias = '\u202Ebox\u200B';
    final conn = FakeConnection(
      (cmd, _) => ok({'device_id': 'd9', 'alias': alias, 'hpk': b64uEncode(List.filled(32, 1))}),
    );
    final run = PairOverSsh(
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
      hosts: hosts,
      pushKeys: FakePushKeys(),
      endpoints: endpoints,
    );
    expect((await run('h1', deviceName: 'Phone')).alias, 'box');
    alias = 'x' * 65;
    await expectLater(run('h1', deviceName: 'Phone'), throwsA(isA<PairingFailure>()));
  });

  test('SSH pairing refuses a device id that is not b64u', () async {
    await hosts.save(testHost(hookPath: '/h/openmosh-hook'));
    final conn = FakeConnection(
      (cmd, _) => ok({'device_id': '../d', 'alias': 'box', 'hpk': b64uEncode(List.filled(32, 1))}),
    );
    final run = PairOverSsh(
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
      hosts: hosts,
      pushKeys: FakePushKeys(),
      endpoints: endpoints,
    );
    await expectLater(run('h1', deviceName: 'Phone'), throwsA(isA<PairingFailure>()));
  });

  test('SSH pairing sends name, push key and endpoint on stdin and stores the reply', () async {
    await hosts.save(testHost(hookPath: '/h/openmosh-hook'));
    final conn = FakeConnection(
      (cmd, _) => ok({'device_id': 'd9', 'alias': 'box', 'hpk': b64uEncode(List.filled(32, 1))}),
    );
    final connections = HostConnections(
      hosts: hosts,
      vault: FakeVault(),
      connector: FakeConnector(() => conn),
    );
    final updated = await PairOverSsh(
      connections: connections,
      hosts: hosts,
      pushKeys: FakePushKeys(),
      endpoints: endpoints,
    )('h1', deviceName: 'Phone');
    expect(conn.commands.single, 'sh -s');
    final script = conn.scripts.single;
    expect(script, startsWith("printf '%s' '"));
    expect(script, endsWith("' | '/h/openmosh-hook' 'pair-ssh' '--json'\n"));
    final json = script.substring("printf '%s' '".length, script.indexOf("' | '"));
    expect(jsonDecode(json), {
      'name': 'Phone',
      'ppk': b64uEncode(List.filled(32, 3)),
      'endpoint': 'https://ntfy.sh/upXYZ',
    });
    expect(updated.deviceId, 'd9');
    expect(updated.pairedVia, PairedVia.ssh);
    expect(updated.fingerprint, testHost().fingerprint);
  });

  test('rotated endpoint is re-sent once with devices set-endpoint', () async {
    await hosts.save(testHost(deviceId: 'd1').copyWith(endpointSent: 'https://old'));
    final sent = <List<String>>[];
    final sync = SyncPushEndpoint(hosts: hosts, endpoints: endpoints);
    Future<Object?> run(HookCommand c) async {
      sent.add(c.argv);
      return null;
    }

    await sync((await hosts.byId('h1'))!, run);
    await sync((await hosts.byId('h1'))!, run);
    expect(sent, [
      ['devices', 'set-endpoint', 'd1', 'https://ntfy.sh/upXYZ', '--json'],
    ]);
  });

  test('a host paired without notifications gets them once the distributor registers', () async {
    await hosts.save(
      testHost(deviceId: 'd1', hpk: b64uEncode(List.filled(32, 1))).copyWith(endpointSent: ''),
    );
    expect((await hosts.byId('h1'))!.pushEnabled, isFalse);
    final sent = <List<String>>[];
    await SyncPushEndpoint(hosts: hosts, endpoints: endpoints)((await hosts.byId('h1'))!, (
      c,
    ) async {
      sent.add(c.argv);
      return null;
    });
    expect(sent.single, ['devices', 'set-endpoint', 'd1', 'https://ntfy.sh/upXYZ', '--json']);
    expect((await hosts.byId('h1'))!.pushEnabled, isTrue);
  });

  test('hosts saved before endpoints were tracked still count as push enabled', () {
    final legacy = testHost(deviceId: 'd1', hpk: b64uEncode(List.filled(32, 1)));
    expect(legacy.endpointSent, isNull);
    expect(legacy.pushEnabled, isTrue);
  });
}
