/// QR pairing (primary, TRD §6.3) and SSH pairing (secondary, §6.4).
library;

import 'dart:convert';

import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../hosts/domain/entities/host.dart';
import '../../../hosts/domain/repositories/host_repository.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../../../inbox/domain/entities/push_endpoint.dart';
import '../../../inbox/domain/repositories/inbox_ports.dart';
import '../../../keys/domain/entities/ssh_key_info.dart';
import '../../../keys/domain/repositories/key_vault.dart';
import '../entities/pair_payload.dart';
import '../entities/pairing_messages.dart';
import '../repositories/pairing_gateway.dart';

final class PairWithQr {
  const PairWithQr({
    required this.gateway,
    required this.vault,
    required this.pushKeys,
    required this.endpoints,
    required this.hosts,
    required this.deviceName,
    required this.newId,
    required this.now,
  });

  final PairingGateway gateway;
  final KeyVault vault;
  final PushKeyStore pushKeys;
  final PushEndpointSource endpoints;
  final HostRepository hosts;
  final String deviceName;
  final String Function() newId;
  final DateTime Function() now;

  /// Parses and validates the code without side effects.
  PairPayload inspect(String raw) => PairPayload.parse(raw, now: now().toUtc());

  Future<Host> call(String raw) async {
    final code = inspect(raw);
    final key = await vault.ensureDeviceKey(comment: 'openmosh:$deviceName');
    final ppk = await pushKeys.publicKey();
    final endpoint = await endpoints.currentEndpoint();
    if (!isAllowedPushEndpoint(endpoint)) {
      throw const PushFailure('The push endpoint must use https.');
    }
    // Re-check expiry: key generation and push registration take time.
    if (!now().toUtc().isBefore(code.expiresAt)) throw PairCodeFailure(PairCodeError.expired);

    final reply = await gateway.exchange(
      code,
      PairRequestBody(
        token: code.token,
        name: deviceName,
        sshPublicKey: key.publicKey,
        pushPublicKey: ppk,
        endpoint: endpoint,
      ),
    );
    final host = Host(
      id: newId(),
      alias: reply.alias.isNotEmpty ? reply.alias : code.alias,
      address: code.ip,
      port: code.sshPort,
      user: code.sshUser,
      fingerprint: code.sshFingerprint,
      pairedVia: PairedVia.qr,
      createdAt: now(),
      keyId: SshKeyInfo.deviceKeyId,
      deviceId: reply.deviceId,
      hostPushKey: b64uEncode(code.hostPublicKey),
      endpointSent: endpoint,
    );
    await hosts.save(host);
    return host;
  }
}

final class PairOverSsh {
  const PairOverSsh({
    required this.connections,
    required this.hosts,
    required this.pushKeys,
    required this.endpoints,
    required this.deviceName,
  });

  final HostConnections connections;
  final HostRepository hosts;
  final PushKeyStore pushKeys;
  final PushEndpointSource endpoints;
  final String deviceName;

  Future<Host> call(String hostId) async {
    final host = await hosts.byId(hostId);
    if (host == null) throw const ValidationFailure('Unknown host.');
    final endpoint = await endpoints.currentEndpoint();
    if (!isAllowedPushEndpoint(endpoint)) {
      throw const PushFailure('The push endpoint must use https.');
    }
    final stdin = utf8.encode(jsonEncode({
      'name': deviceName,
      'ppk': b64uEncode(await pushKeys.publicKey()),
      'endpoint': endpoint,
    }));
    final data = await connections.runHook(hostId, HookCommand.pairSsh(), stdin: stdin);
    if (data is! Map<String, Object?>) throw const PairingFailure('Unexpected pairing reply.');
    final id = data['device_id'];
    final hpk = data['hpk'];
    if (id is! String || id.isEmpty || hpk is! String) {
      throw const PairingFailure('Unexpected pairing reply.');
    }
    try {
      if (b64uDecode(hpk).length != 32) throw const FormatException();
    } on FormatException {
      throw const PairingFailure('Unexpected pairing reply.');
    }
    final alias = data['alias'];
    final updated = (await hosts.byId(hostId))!.copyWith(
      deviceId: id,
      hostPushKey: hpk,
      endpointSent: endpoint,
      pairedVia: PairedVia.ssh,
      alias: alias is String && alias.isNotEmpty ? alias : null,
    );
    await hosts.save(updated);
    return updated;
  }
}

/// Registered as a post-connect hook: re-sends a rotated push endpoint
/// with `devices set-endpoint` (TRD §6.6).
final class SyncPushEndpoint {
  const SyncPushEndpoint({required this.hosts, required this.endpoints});

  final HostRepository hosts;
  final PushEndpointSource endpoints;

  Future<void> call(Host host, Future<Object?> Function(HookCommand) run) async {
    if (host.deviceId == null) return;
    final current = await endpoints.knownEndpoint();
    if (current == null || current == host.endpointSent || !isAllowedPushEndpoint(current)) return;
    await run(HookCommand.setEndpoint(host.deviceId!, current));
    final fresh = await hosts.byId(host.id);
    if (fresh != null) await hosts.save(fresh.copyWith(endpointSent: current));
  }
}
