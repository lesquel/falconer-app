import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/status_badge.dart';
import '../../../../shared/ui/molecules/fingerprint_card.dart';
import '../../../sessions/domain/entities/remote_session.dart';
import '../../domain/entities/host.dart';

class HostDetailView extends StatelessWidget {
  const HostDetailView({
    super.key,
    required this.host,
    required this.sessions,
    required this.agents,
    required this.loading,
    required this.onLoad,
    required this.onShell,
    required this.onAttach,
    required this.onEnablePush,
    this.error,
  });

  final Host host;
  final List<RemoteSession>? sessions;
  final List<AgentInfo>? agents;
  final bool loading;
  final Widget? error;
  final VoidCallback onLoad;
  final VoidCallback onShell;
  final ValueChanged<RemoteSession> onAttach;
  final VoidCallback onEnablePush;

  BadgeTone _tone(AgentState s) => switch (s) {
        AgentState.blocked => BadgeTone.attention,
        AgentState.working => BadgeTone.success,
        AgentState.done => BadgeTone.neutral,
        _ => BadgeTone.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${host.user}@${host.address}:${host.port}', style: t.bodyMedium),
        const SizedBox(height: 8),
        FingerprintCard(label: 'Pinned host key', fingerprint: host.fingerprint),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: onShell, icon: const Icon(Icons.terminal), label: const Text('Shell')),
          OutlinedButton.icon(
            onPressed: loading ? null : onLoad,
            icon: const Icon(Icons.refresh),
            label: Text(sessions == null ? 'Load sessions' : 'Refresh'),
          ),
          if (!host.pushEnabled)
            OutlinedButton.icon(
              onPressed: onEnablePush,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Enable notifications'),
            ),
        ]),
        if (loading) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ?error,
        if (sessions != null) ...[
          const SizedBox(height: 16),
          Text('Sessions', style: t.titleMedium),
          if (sessions!.isEmpty) const ListTile(title: Text('No Herdr or tmux sessions')),
          for (final s in sessions!)
            ListTile(
              leading: Icon(s.kind == SessionKind.herdr ? Icons.dashboard_outlined : Icons.view_column_outlined),
              title: Text(s.name),
              subtitle: Text(s.kind.name + (s.attached ? ' · attached' : '')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onAttach(s),
            ),
        ],
        if (agents != null) ...[
          const SizedBox(height: 16),
          Text('Agents', style: t.titleMedium),
          if (agents!.isEmpty) const ListTile(title: Text('No agents running')),
          for (final a in agents!)
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined),
              title: Text(a.agent),
              subtitle: Text(a.title ?? a.paneId, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: StatusBadge(label: a.state.name, tone: _tone(a.state)),
            ),
        ],
      ],
    );
  }
}
