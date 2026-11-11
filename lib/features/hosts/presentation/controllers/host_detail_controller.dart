import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../sessions/domain/entities/remote_session.dart';

final class HostDetailState {
  const HostDetailState({
    this.sessions,
    this.agents,
    this.loading = false,
    this.error,
    this.herdr = false,
  });
  final List<RemoteSession>? sessions;
  final List<AgentInfo>? agents;

  /// The host's hook speaks the Herdr navigator protocol.
  final bool herdr;
  final bool loading;
  final Object? error;
}

class HostDetailController extends Notifier<HostDetailState> {
  HostDetailController(this.hostId);
  final String hostId;

  @override
  HostDetailState build() => const HostDetailState();

  Future<void> load() async {
    state = HostDetailState(
      sessions: state.sessions,
      agents: state.agents,
      herdr: state.herdr,
      loading: true,
    );
    try {
      final catalog = ref.read(sessionCatalogProvider);
      final sessions = await catalog.sessions(hostId);
      final agents = await catalog.agents(hostId);
      final herdr = await _supportsHerdr();
      state = HostDetailState(sessions: sessions, agents: agents, herdr: herdr);
      try {
        await ref.read(syncInboxProvider)(hostId);
      } catch (e) {
        Log.warning('inbox', 'sync failed');
      }
    } catch (e) {
      state = HostDetailState(
        sessions: state.sessions,
        agents: state.agents,
        herdr: state.herdr,
        error: e,
      );
    }
  }

  /// Without the navigator protocol the entry is hidden; a failed check is a no.
  Future<bool> _supportsHerdr() async {
    try {
      return await ref.read(herdrRepositoryProvider).supportsHerdr(hostId);
    } catch (_) {
      return false;
    }
  }

  Future<void> enablePush(String deviceName) async {
    state = HostDetailState(
      sessions: state.sessions,
      agents: state.agents,
      herdr: state.herdr,
      loading: true,
    );
    try {
      final host = await ref.read(hostRepositoryProvider).byId(hostId);
      if (host != null && host.paired) {
        // Paired by QR without notifications: only the endpoint is missing.
        await ref.read(enablePushProvider)(hostId);
      } else {
        await ref.read(pairOverSshProvider)(hostId, deviceName: deviceName);
      }
      state = HostDetailState(sessions: state.sessions, agents: state.agents, herdr: state.herdr);
    } catch (e) {
      state = HostDetailState(
        sessions: state.sessions,
        agents: state.agents,
        herdr: state.herdr,
        error: e,
      );
    }
  }
}

final hostDetailProvider = NotifierProvider.autoDispose
    .family<HostDetailController, HostDetailState, String>(HostDetailController.new);
