/// In-app device management (SEC-11): list the host's paired devices and
/// revoke one. Revoking is a sensitive action and always asks for user
/// verification first.
library;

import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../keys/domain/repositories/key_vault.dart';
import '../entities/paired_device.dart';
import '../repositories/host_repository.dart';
import 'host_connections.dart';

final class PairedDevices {
  const PairedDevices({required this.connections, required this.hosts, required this.auth});

  final HostConnections connections;
  final HostRepository hosts;
  final UserAuthenticator auth;

  Future<List<PairedDevice>> list(String hostId) async {
    final data = await connections.runHook(hostId, HookCommand.devicesList());
    final items = data is List ? data : (data is Map ? data['devices'] : null);
    if (items is! List) return const [];
    final me = (await hosts.byId(hostId))?.deviceId;
    return items.map((d) => PairedDevice.fromJson(d, thisDeviceId: me)).nonNulls.toList();
  }

  /// Returns true when [device] was this phone: the host no longer accepts
  /// its key, so the open connection is dropped.
  Future<bool> revoke(String hostId, PairedDevice device) async {
    final cmd = HookCommand.devicesRevoke(device.id);
    if (!await auth.authenticate('Revoke ${device.name}')) throw const UserCancelledFailure();
    await connections.runHook(hostId, cmd);
    final me = (await hosts.byId(hostId))?.deviceId;
    if (me == device.id) {
      await connections.disconnect(hostId);
      return true;
    }
    return false;
  }
}
