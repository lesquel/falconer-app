import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/herdr_snapshot.dart';
import 'herdr_status.dart';

/// Workspaces → tabs → panes of a Herdr session with live agent status.
/// Panes waiting on the user are highlighted. Purely presentational.
class HerdrNavigatorView extends StatelessWidget {
  const HerdrNavigatorView({
    super.key,
    required this.snapshot,
    required this.onOpenPane,
    required this.onCreateWorkspace,
    required this.onRenameWorkspace,
    required this.onCloseWorkspace,
    required this.onCreateTab,
    required this.onRenameTab,
    required this.onCloseTab,
    required this.onStartAgent,
    required this.onRetry,
    this.error,
    this.session,
    this.selectedPaneId,
    this.onBack,
  });

  final HerdrSnapshot? snapshot;
  final Object? error;
  final String? session;
  final String? selectedPaneId;
  final VoidCallback? onBack;
  final VoidCallback onRetry;
  final ValueChanged<HerdrPane> onOpenPane;
  final VoidCallback onCreateWorkspace;
  final ValueChanged<HerdrWorkspace> onRenameWorkspace;
  final ValueChanged<HerdrWorkspace> onCloseWorkspace;
  final ValueChanged<HerdrWorkspace> onCreateTab;
  final ValueChanged<HerdrTab> onRenameTab;
  final ValueChanged<HerdrTab> onCloseTab;
  final ValueChanged<HerdrPane> onStartAgent;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final snap = snapshot;
    final Widget body;
    if (snap == null) {
      body = error != null
          ? FailurePanel(failure: error!, onRetry: onRetry)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l.herdrLoading),
                ],
              ),
            );
    } else if (snap.workspaces.isEmpty) {
      body = Center(
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
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.herdrOutOfDate,
                key: const Key('herdr-stale'),
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ),
          for (final w in snap.workspaces) _workspace(context, snap, w),
        ],
      );
    }
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                if (onBack != null) ...[
                  CircleIconButton(icon: Icons.chevron_left, tooltip: l.back, onPressed: onBack),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.herdrNavigator,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      if (session != null)
                        Text(session!, style: TextStyle(fontSize: 12, color: c.muted)),
                    ],
                  ),
                ),
                if (snap != null && snap.workspaces.isNotEmpty)
                  IconButton(
                    key: const Key('herdr-new-workspace'),
                    tooltip: l.herdrNewWorkspace,
                    icon: const Icon(Icons.add),
                    onPressed: onCreateWorkspace,
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }

  Widget _workspace(BuildContext context, HerdrSnapshot snap, HerdrWorkspace w) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final tabs = snap.tabsOf(w.id);
    return Padding(
      key: Key('ws-${w.id}'),
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspaces_outline, size: 20, color: c.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  w.label.isEmpty ? w.id : w.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
              if (w.focused) _FocusedMark(label: l.herdrFocused),
              PopupMenuButton<VoidCallback>(
                key: Key('ws-menu-${w.id}'),
                tooltip: l.herdrMoreActions,
                onSelected: (f) => f(),
                itemBuilder: (_) => [
                  PopupMenuItem(value: () => onCreateTab(w), child: Text(l.herdrNewTab)),
                  PopupMenuItem(value: () => onRenameWorkspace(w), child: Text(l.herdrRename)),
                  PopupMenuItem(value: () => onCloseWorkspace(w), child: Text(l.close)),
                ],
              ),
            ],
          ),
          if (tabs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 28, bottom: 4),
              child: Text(l.herdrNoTabs, style: TextStyle(color: c.muted)),
            ),
          for (final t in tabs) _tab(context, snap, t),
        ],
      ),
    );
  }

  Widget _tab(BuildContext context, HerdrSnapshot snap, HerdrTab t) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final blocked = t.status == HerdrStatus.blocked;
    return Padding(
      key: Key('tab-${t.id}'),
      padding: const EdgeInsets.only(top: 8),
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
                if (t.focused) _FocusedMark(label: l.herdrFocused),
                PopupMenuButton<VoidCallback>(
                  key: Key('tab-menu-${t.id}'),
                  tooltip: l.herdrMoreActions,
                  onSelected: (f) => f(),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: () => onRenameTab(t), child: Text(l.herdrRename)),
                    PopupMenuItem(value: () => onCloseTab(t), child: Text(l.close)),
                  ],
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
              PopupMenuButton<VoidCallback>(
                key: Key('pane-menu-${p.id}'),
                tooltip: l.herdrMoreActions,
                onSelected: (f) => f(),
                itemBuilder: (_) => [
                  PopupMenuItem(value: () => onStartAgent(p), child: Text(l.herdrStartAgentIn)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FocusedMark extends StatelessWidget {
  const _FocusedMark({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 14, color: c.muted),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }
}
