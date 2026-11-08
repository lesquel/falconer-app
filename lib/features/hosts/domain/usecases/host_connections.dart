/// Opens and reuses one SSH connection per host. A new connection always
/// goes through the key vault, which asks for biometrics/device credential.
library;

import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_client.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../../shared/ssh/domain/ssh_ports.dart';
import '../../../keys/domain/entities/ssh_key_info.dart';
import '../../../keys/domain/repositories/key_vault.dart';
import '../entities/host.dart';
import '../repositories/host_repository.dart';

typedef OnConnected = Future<void> Function(Host host, SshConnection conn);

final class HostConnections {
  HostConnections({
    required this.hosts,
    required this.vault,
    required this.connector,
    this.hook = const HookClient(),
    this.onVerified,
  });

  final HostRepository hosts;
  final KeyVault vault;
  final SshConnector connector;
  final HookClient hook;

  /// Called after the key vault verified the user to unlock a key, so a
  /// terminal opened right after is not asked for a second verification.
  final void Function()? onVerified;
  final List<OnConnected> _onConnected = [];
  final Map<String, SshConnection> _open = {};
  final Map<String, Future<SshConnection>> _pending = {};

  void addOnConnected(OnConnected f) => _onConnected.add(f);

  bool isConnected(String hostId) => _open[hostId]?.isClosed == false;

  Future<SshConnection> connection(String hostId) {
    final live = _open[hostId];
    if (live != null && !live.isClosed) return Future.value(live);
    // Block body: returning the removed future from whenComplete would make
    // the future wait on itself.
    return _pending[hostId] ??= _connect(hostId).whenComplete(() {
      _pending.remove(hostId);
    });
  }

  Future<SshConnection> _connect(String hostId) async {
    final host = await hosts.byId(hostId);
    if (host == null) throw const ValidationFailure('Unknown host.');
    final keyId = host.keyId ?? SshKeyInfo.deviceKeyId;
    final private = await vault.unlockPrivate(
      keyId,
      reason: 'Unlock key to connect to ${host.alias}',
    );
    onVerified?.call();
    final conn = await connector.connect(
      SshEndpoint(
        host: host.address,
        port: host.port,
        user: host.user,
        pinnedFingerprint: host.fingerprint,
      ),
      privateKeyOpenssh: private,
    );
    _open[hostId] = conn;
    Log.info('ssh', 'connected host=${host.id}');
    for (final f in _onConnected) {
      try {
        await f(host, conn);
      } catch (e) {
        Log.error('ssh', 'post-connect hook failed', e);
      }
    }
    return conn;
  }

  /// Runs a hook command, resolving and caching the hook path if needed.
  Future<Object?> runHook(String hostId, HookCommand cmd, {List<int>? stdin}) async {
    final conn = await connection(hostId);
    var host = (await hosts.byId(hostId))!;
    var path = host.hookPath;
    if (path == null) {
      path = await hook.resolvePath(conn);
      host = host.copyWith(hookPath: path);
      await hosts.save(host);
    }
    return hook.call(conn, path, cmd, stdin: stdin);
  }

  Future<void> disconnect(String hostId) async {
    final c = _open.remove(hostId);
    await c?.close();
  }

  Future<void> disconnectAll() async {
    for (final id in _open.keys.toList()) {
      await disconnect(id);
    }
  }
}
