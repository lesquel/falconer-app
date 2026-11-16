import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:openmosh/features/hosts/domain/entities/host.dart';
import 'package:openmosh/features/hosts/domain/repositories/host_repository.dart';
import 'package:openmosh/features/keys/domain/entities/ssh_key_info.dart';
import 'package:openmosh/features/keys/domain/repositories/key_vault.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ssh/domain/ssh_ports.dart';

Host testHost({String id = 'h1', String? hookPath, String? deviceId, String? hpk}) => Host(
  id: id,
  alias: 'work',
  address: '100.100.1.2',
  port: 22,
  user: 'me',
  fingerprint: 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM',
  pairedVia: PairedVia.qr,
  createdAt: DateTime.utc(2026),
  hookPath: hookPath,
  deviceId: deviceId,
  hostPushKey: hpk,
);

class FakeHostRepository implements HostRepository {
  final Map<String, Host> rows = {};
  final _ctrl = StreamController<List<Host>>.broadcast();

  @override
  Future<List<Host>> all() async => rows.values.toList();
  @override
  Future<Host?> byId(String id) async => rows[id];
  @override
  Future<Host?> byDeviceId(String d) async => rows.values.where((h) => h.deviceId == d).firstOrNull;
  @override
  Future<void> delete(String id) async => rows.remove(id);
  @override
  Future<void> save(Host host) async {
    rows[host.id] = host;
    _ctrl.add(rows.values.toList());
  }

  @override
  Stream<List<Host>> watchAll() => _ctrl.stream;
}

class FakeVault implements KeyVault {
  int unlocks = 0;
  bool cancel = false;

  /// Keys still in the v0.1 namespace.
  int legacyKeys = 0;
  int migrations = 0;
  AppFailure? migrationFailure;

  @override
  Future<bool> hasLegacyKeys() async => legacyKeys > 0;

  @override
  Future<int> migrateLegacyKeys() async {
    migrations++;
    if (migrationFailure != null) throw migrationFailure!;
    final n = legacyKeys;
    legacyKeys = 0;
    return n;
  }

  @override
  Future<String> unlockPrivate(String id, {required String reason}) async {
    if (cancel) throw const UserCancelledFailure();
    unlocks++;
    return 'PRIVATE';
  }

  @override
  Future<SshKeyInfo> ensureDeviceKey({required String comment}) async => SshKeyInfo(
    id: SshKeyInfo.deviceKeyId,
    label: 'device',
    publicKey: 'ssh-ed25519 AAAAC3 device',
    fingerprint: 'SHA256:x',
    imported: false,
    createdAt: DateTime.utc(2026),
  );

  @override
  Future<SshKeyInfo?> byId(String id) async => null;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<SshKeyInfo> generate(String label) => throw UnimplementedError();
  @override
  Future<SshKeyInfo> import(String label, String privateOpenssh, {String? passphrase}) =>
      throw UnimplementedError();
  @override
  Stream<List<SshKeyInfo>> watchAll() => const Stream.empty();
}

class FakeConnection implements SshConnection {
  FakeConnection(this.responder);
  final ExecOutput Function(String cmd, List<int>? stdin) responder;
  final List<String> commands = [];
  final List<List<int>?> stdins = [];
  bool closed = false;
  @override
  String? closeReason;

  /// Scripts written to `sh -s` on stdin (hook calls are shell-independent).
  List<String> get scripts => [for (final s in stdins) s == null ? '' : utf8.decode(s)];

  @override
  Future<ExecOutput> exec(String command, {List<int>? stdin}) async {
    commands.add(command);
    stdins.add(stdin);
    return responder(command, stdin);
  }

  @override
  bool get isClosed => closed;
  @override
  Future<void> close() async => closed = true;
  @override
  Future<ShellChannel> openShell({required int cols, required int rows}) =>
      throw UnimplementedError();
  @override
  Future<String> upload(String localPath, String remoteName) async =>
      '/home/me/.falconer/uploads/$remoteName';
}

ExecOutput ok(Object? data) => ExecOutput(
  exitCode: 0,
  stdout: Uint8List.fromList(utf8.encode(jsonEncode({'ok': true, 'data': data}))),
  stderr: Uint8List(0),
);

ExecOutput text(String s, {int code = 0}) =>
    ExecOutput(exitCode: code, stdout: Uint8List.fromList(utf8.encode(s)), stderr: Uint8List(0));

class FakeConnector implements SshConnector {
  FakeConnector(this.make);
  FakeConnection Function() make;
  AppFailure? fail;
  final List<SshEndpoint> endpoints = [];
  String probe = 'SHA256:i2cBF5DBtTy5/U7Y27668/2F1HhY/qwC4eALG8QAiQM';

  @override
  Future<SshConnection> connect(SshEndpoint endpoint, {required String privateKeyOpenssh}) async {
    endpoints.add(endpoint);
    if (fail != null) throw fail!;
    return make();
  }

  @override
  Future<String> probeFingerprint(String host, int port) async => probe;
}

class FakePushKeys implements PushKeyStore {
  @override
  Future<Uint8List> privateKey() async => Uint8List.fromList(List.filled(32, 2));
  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList(List.filled(32, 3));
}
