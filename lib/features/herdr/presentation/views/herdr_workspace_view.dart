import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/herdr_snapshot.dart';
import 'herdr_frame.dart';
import 'herdr_status.dart';

/// Screen 2 of the navigator: one workspace's tabs with their panes, agents
/// with live status and plain terminals, plus "New terminal". Purely
/// presentational.
class HerdrWorkspaceView extends StatelessWidget {
  const HerdrWorkspaceView({
    super.key,
    required this.workspaceId,
    required this.snapshot,
    required this.onOpenPane,
    required this.onNewTerminal,
    required this.onRenameTab,
    required this.onCloseTab,
    required this.onStartAgent,
    required this.onRetry,
    this.error,
    this.session,
    this.selectedPaneId,
    this.onBack,
  });

  final String workspaceId;
  final HerdrSnapshot? snapshot;
  final Object? error;
  final String? session;
  final String? selectedPaneId;
  final VoidCallback? onBack;
  final VoidCallback onRetry;
  final ValueChanged<HerdrPane> onOpenPane;
  final ValueChanged<HerdrWorkspace> onNewTerminal;
  final ValueChanged<HerdrTab> onRenameTab;
  final ValueChanged<HerdrTab> onCloseTab;
  final ValueChanged<HerdrPane> onStartAgent;

  HerdrWorkspace? get _workspace =>
      snapshot?.workspaces.where((w) => w.id == workspaceId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final ws = _workspace;
    return HerdrFrame(
      title: ws == null ? l.herdrNavigator : (ws.label.isEmpty ? ws.id : ws.label),
      subtitle: session,
      snapshot: snapshot,
      error: error,
      onRetry: onRetry,
      onBack: onBack,
      builder: (context, snap) {
        if (ws == null) {
          return Center(
            child: Text(
              l.herdrWorkspaceGone,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.muted),
            ),
          );
        }
        final tabs = snap.tabsOf(ws.id);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('herdr-new-terminal'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                onPressed: () => onNewTerminal(ws),
                icon: const Icon(Icons.add),
                label: Text(l.herdrNewTerminal),
              ),
            ),
            if (tabs.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(l.herdrNoTabs, style: TextStyle(color: c.muted)),
              ),
            for (final t in tabs) _tab(context, snap, t),
          ],
        );
      },
    );
  }

  Widget _tab(BuildContext context, HerdrSnapshot snap, HerdrTab t) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final blocked = t.status == HerdrStatus.blocked;
    return Padding(
      key: Key('tab-${t.id}'),
      padding: const EdgeInsets.only(top: 12),
      child: MoshTile(
        radius: MoshRadii.tile,
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.number > 0 ? '${t.number}  ${t.label}' : t.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: blocked ? c.accent : c.foreground,
                    ),
                  ),
                ),
                if (t.focused) const HerdrFocusedMark(),
                HerdrMenu(
                  key: Key('tab-menu-${t.id}'),
                  items: [(l.herdrRename, () => onRenameTab(t)), (l.close, () => onCloseTab(t))],
                ),
              ],
            ),
            for (final p in snap.panesOf(t.id)) _pane(context, p),
          ],
        ),
      ),
    );
  }

  Widget _pane(BuildContext context, HerdrPane p) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final blocked = p.status == HerdrStatus.blocked;
    final selected = p.id == selectedPaneId;
    return Padding(
      padding: const EdgeInsets.only(top: 6, right: 8),
      child: Material(
        key: Key('pane-${p.id}'),
        color: blocked
            ? c.accent.withValues(alpha: 0.14)
            : selected
            ? c.surfaceHigh
            : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoshRadii.key),
          side: blocked ? BorderSide(color: c.accent, width: 2) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          minTileHeight: 56,
          onTap: () => onOpenPane(p),
          onLongPress: () => onStartAgent(p),
          leading: Icon(p.agent == null ? Icons.terminal : Icons.smart_toy_outlined),
          title: Text(
            p.agent ?? l.herdrShellPane,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            p.focused ? '${p.id} · ${l.herdrFocused}' : p.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (p.agent != null) HerdrStatusBadge(p.status),
              HerdrMenu(
                key: Key('pane-menu-${p.id}'),
                items: [(l.herdrStartAgentIn, () => onStartAgent(p))],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
