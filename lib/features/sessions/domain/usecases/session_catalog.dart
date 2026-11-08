import '../../../../shared/hook/domain/hook_command.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../entities/remote_session.dart';

/// Lists sessions and agents through `openmosh-hook … --json`.
final class SessionCatalog {
  const SessionCatalog(this.connections);
  final HostConnections connections;

  Future<List<RemoteSession>> sessions(String hostId) async => _list(
    await connections.runHook(hostId, HookCommand.sessionsList()),
    'sessions',
  ).map(RemoteSession.fromJson).nonNulls.toList();

  Future<List<AgentInfo>> agents(String hostId) async => _list(
    await connections.runHook(hostId, HookCommand.agentsList()),
    'agents',
  ).map(AgentInfo.fromJson).nonNulls.toList();

  static List<Object?> _list(Object? data, String key) {
    if (data is List) return data;
    if (data is Map && data[key] is List) return data[key] as List<Object?>;
    return const [];
  }
}
