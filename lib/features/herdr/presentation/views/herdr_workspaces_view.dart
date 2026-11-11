import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/herdr_snapshot.dart';
import 'herdr_frame.dart';
import 'herdr_status.dart';

/// Screen 1 of the navigator: the Herdr workspaces of a session with how
/// many agents and terminals each holds and whether one needs the user.
/// Purely presentational.
class HerdrWorkspacesView extends StatelessWidget {
  const HerdrWorkspacesView({
    super.key,
    required this.snapshot,
    required this.onOpenWorkspace,
    required this.onCreateWorkspace,
    required this.onRenameWorkspace,
    required this.onCloseWorkspace,
    required this.onRetry,
    this.error,
    this.session,
    this.selectedWorkspaceId,
    this.onBack,
  });

  final HerdrSnapshot? snapshot;
  final Object? error;
  final String? session;
  final String? selectedWorkspaceId;
  final VoidCallback? onBack;
  final VoidCallback onRetry;
  final ValueChanged<HerdrWorkspace> onOpenWorkspace;
  final VoidCallback onCreateWorkspace;
  final ValueChanged<HerdrWorkspace> onRenameWorkspace;
  final ValueChanged<HerdrWorkspace> onCloseWorkspace;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return HerdrFrame(
      title: l.herdrNavigator,
      subtitle: session,
      snapshot: snapshot,
      error: error,
      onRetry: onRetry,
      onBack: onBack,
      actions: [
        if (snapshot?.workspaces.isNotEmpty ?? false)
          IconButton(
            key: const Key('herdr-new-workspace'),
            tooltip: l.herdrNewWorkspace,
            icon: const Icon(Icons.add),
            onPressed: onCreateWorkspace,
          ),
      ],
      builder: (context, snap) {
        if (snap.workspaces.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l.herdrEmpty, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onCreateWorkspace,
                  icon: const Icon(Icons.add),
                  label: Text(l.herdrNewWorkspace),
                ),
              ],
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [for (final w in snap.workspaces) _workspace(context, snap, w)],
        );
      },
    );
  }

  Widget _workspace(BuildContext context, HerdrSnapshot snap, HerdrWorkspace w) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final panes = snap.panes.where((p) => p.workspaceId == w.id).toList();
    final agents = panes.where((p) => p.agent != null).length;
    final terminals = panes.length - agents;
    final blocked =
        panes.any((p) => p.status == HerdrStatus.blocked) ||
        snap.tabsOf(w.id).any((t) => t.status == HerdrStatus.blocked);
    final counts = [
      if (agents > 0) l.herdrAgentCount(agents),
      if (terminals > 0) l.herdrTerminalCount(terminals),
    ];
    final selected = w.id == selectedWorkspaceId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        key: Key('ws-${w.id}'),
        color: blocked
            ? c.accent.withValues(alpha: 0.14)
            : selected
            ? c.surfaceHigh
            : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoshRadii.tile),
          side: blocked ? BorderSide(color: c.accent, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 72,
          contentPadding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          onTap: () => onOpenWorkspace(w),
          leading: Icon(Icons.workspaces_outline, color: blocked ? c.accent : c.muted),
          title: Text(
            w.label.isEmpty ? w.id : w.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          subtitle: Text(counts.isEmpty ? l.herdrNoTabs : counts.join(' · ')),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (blocked) const HerdrStatusBadge(HerdrStatus.blocked),
              if (w.focused) const HerdrFocusedMark(),
              HerdrMenu(
                key: Key('ws-menu-${w.id}'),
                items: [
                  (l.herdrRename, () => onRenameWorkspace(w)),
                  (l.close, () => onCloseWorkspace(w)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
