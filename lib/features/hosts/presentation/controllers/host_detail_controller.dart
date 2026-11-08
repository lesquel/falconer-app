import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../sessions/domain/entities/remote_session.dart';

final class HostDetailState {
  const HostDetailState({this.sessions, this.agents, this.loading = false, this.error});
  final List<RemoteSession>? sessions;
  final List<AgentInfo>? agents;
  final bool loading;
  final Object? error;
}

class HostDetailController extends Notifier<HostDetailState> {
  HostDetailController(this.hostId);
  final String hostId;

  @override
  HostDetailState build() => const HostDetailState();

  Future<void> load() async {
    state = HostDetailState(sessions: state.sessions, agents: state.agents, loading: true);
    try {
      final catalog = ref.read(sessionCatalogProvider);
      final sessions = await catalog.sessions(hostId);
      final agents = await catalog.agents(hostId);
      state = HostDetailState(sessions: sessions, agents: agents);
      try {
        await ref.read(syncInboxProvider)(hostId);
      } catch (e) {
        Log.warning('inbox', 'sync failed');
      }
    } catch (e) {
      state = HostDetailState(sessions: state.sessions, agents: state.agents, error: e);
    }
  }

  Future<void> enablePush(String deviceName) async {
    state = HostDetailState(sessions: state.sessions, agents: state.agents, loading: true);
    try {
      await ref.read(pairOverSshProvider)(hostId, deviceName: deviceName);
      state = HostDetailState(sessions: state.sessions, agents: state.agents);
    } catch (e) {
      state = HostDetailState(sessions: state.sessions, agents: state.agents, error: e);
    }
  }
}

final hostDetailProvider =
    NotifierProvider.autoDispose.family<HostDetailController, HostDetailState, String>(HostDetailController.new);
