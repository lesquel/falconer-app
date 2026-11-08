import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/status_badge.dart';
import '../../../../shared/ui/molecules/fingerprint_card.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
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
    this.devices,
    this.onBack,
    this.onEdit,
    this.onDelete,
  });

  final Host host;
  final List<RemoteSession>? sessions;
  final List<AgentInfo>? agents;
  final bool loading;
  final Widget? error;

  /// The "Paired devices" section.
  final Widget? devices;
  final VoidCallback onLoad;
  final VoidCallback onShell;
  final ValueChanged<RemoteSession> onAttach;
  final VoidCallback onEnablePush;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  BadgeTone _tone(AgentState s) => switch (s) {
    AgentState.blocked => BadgeTone.attention,
    AgentState.working => BadgeTone.success,
    AgentState.done => BadgeTone.neutral,
    _ => BadgeTone.neutral,
  };

  int _count(AgentState s) => agents?.where((a) => a.state == s).length ?? 0;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return ThumbPage(
      onBack: onBack,
      caption: '${host.user}@${host.address}:${host.port}',
      actions: [
        if (onEdit != null)
          IconButton(
            tooltip: 'Edit host',
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        if (onDelete != null)
          IconButton(
            tooltip: 'Delete host',
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
      ],
      title: Text(host.alias),
      subtitle: host.pushEnabled ? 'Notifications on' : 'Notifications off',
      children: [
        if (agents != null && agents!.isNotEmpty) ...[
          Row(
            children: [
              for (final (i, (state, label)) in const [
                (AgentState.blocked, 'waiting'),
                (AgentState.working, 'working'),
                (AgentState.done, 'done'),
              ].indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: MoshTile(
                    radius: MoshRadii.key,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_count(state)}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: state == AgentState.blocked ? c.accent : c.foreground,
                          ),
                        ),
                        Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onShell,
                icon: const Icon(Icons.terminal),
                label: const Text('Shell'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: loading ? null : onLoad,
                icon: const Icon(Icons.refresh),
                label: Text(sessions == null ? 'Load sessions' : 'Refresh'),
              ),
            ),
          ],
        ),
        if (!host.pushEnabled) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onEnablePush,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Enable notifications'),
          ),
        ],
        if (loading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ?error,
        if (sessions != null) ...[
          const SectionLabel('Sessions'),
          if (sessions!.isEmpty) const _Line(title: 'No Herdr or tmux sessions'),
          for (final s in sessions!)
            _Line(
              icon: s.kind == SessionKind.herdr
                  ? Icons.dashboard_outlined
                  : Icons.view_column_outlined,
              title: s.name,
              subtitle: s.kind.name + (s.attached ? ' · attached' : ''),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onAttach(s),
            ),
        ],
        if (agents != null) ...[
          const SectionLabel('Agents'),
          if (agents!.isEmpty) const _Line(title: 'No agents running'),
          for (final a in agents!)
            _Line(
              icon: Icons.smart_toy_outlined,
              title: a.agent,
              subtitle: a.title ?? a.paneId,
              trailing: StatusBadge(label: a.state.name, tone: _tone(a.state)),
            ),
        ],
        ?devices,
        const SizedBox(height: 10),
        FingerprintCard(label: 'Pinned host key', fingerprint: host.fingerprint),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.title, this.icon, this.subtitle, this.trailing, this.onTap});
  final String title;
  final IconData? icon;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: MoshTile(
      padding: EdgeInsets.zero,
      radius: MoshRadii.tile,
      onTap: onTap,
      child: ListTile(
        leading: icon == null ? null : Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: trailing,
      ),
    ),
  );
}
