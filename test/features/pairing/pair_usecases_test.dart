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
    return const PairResponse(deviceId: 'dev123', alias: 'workstation');
  }
}

class FakeEndpoints implements PushEndpointSource {
  FakeEndpoints(this.url);
  String url;
  @override
  Future<String> currentEndpoint() async => url;
  @override
  Future<String?> knownEndpoint() async => url;
}

String code({int exp = 2000, String ip = '100.101.102.103'}) {
  final json = {
    'v': 1,
    'alias': 'ws',
    'addr': 'ws.tail.ts.net',
    'ip': ip,
    'ssh_port': 2222,
    'ssh_user': 'me',
    'ssh_fp': 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM',
    'hpk': b64uEncode(List.filled(32, 7)),
    'port': 41000,
    'tok': b64uEncode(List.filled(32, 9)),
    'exp': exp,
  };
  return 'openmosh://pair?d=${b64uEncode(utf8.encode(jsonEncode(json)))}';
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
    expect(sent.token, List.filled(32, 9));
    expect(sent.sshPublicKey, 'ssh-ed25519 AAAAC3 device');
    expect(sent.pushPublicKey, List.filled(32, 3));
    expect(sent.endpoint, 'https://ntfy.sh/upXYZ');
    expect(sent.name, 'Phone');

    expect(host.fingerprint, 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM');
    expect(host.address, '100.101.102.103');
    expect(host.port, 2222);
    expect(host.deviceId, 'dev123');
    expect(host.hostPushKey, b64uEncode(List.filled(32, 7)));
    expect(host.pairedVia, PairedVia.qr);
    expect(hosts.rows['host-1'], isNotNull);
  });

  test('expired code makes no network call and saves nothing', () async {
    await expectLater(pair(code(exp: 1000), deviceName: 'Phone'), throwsA(isA<PairCodeFailure>()));
    expect(gateway.sent, isNull);
    expect(hosts.rows, isEmpty);
  });

  test('plain http push endpoints outside the tailnet are refused', () async {
    endpoints.url = 'http://ntfy.example.com/up';
    await expectLater(pair(code(), deviceName: 'Phone'), throwsA(isA<PushFailure>()));
    expect(gateway.sent, isNull);
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
    expect(conn.commands.single, "'/h/openmosh-hook' 'pair-ssh' '--json'");
    expect(jsonDecode(utf8.decode(conn.stdins.single!)), {
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
}
