import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n.dart';
import '../views/herdr_workspace_view.dart';
import '../views/herdr_workspaces_view.dart';
import 'herdr_screen_state.dart';
import 'herdr_workspace_container.dart';

export 'herdr_screen_state.dart' show agentViewLocation, herdrSplitWidth;

/// Screen 1 of the Herdr navigator: the session's workspaces. Tapping one
/// opens its terminals; on a tablet they show beside the list, from the
/// same long-poll loop.
class HerdrNavigatorContainer extends ConsumerStatefulWidget {
  const HerdrNavigatorContainer({super.key, required this.hostId, this.session});
  final String hostId;
  final String? session;

  @override
  ConsumerState<HerdrNavigatorContainer> createState() => _HerdrNavigatorContainerState();
}

class _HerdrNavigatorContainerState extends HerdrScreenState<HerdrNavigatorContainer> {
  @override
  String get hostId => widget.hostId;
  @override
  String? get session => widget.session;

  bool _wide = false;
  String? _selected;

  void _openWorkspace(String id) {
    if (_wide) {
      setState(() => _selected = id);
      return;
    }
    unawaited(pushCovering(herdrWorkspaceLocation(hostId, id, session: session)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          _wide = box.maxWidth >= herdrSplitWidth;
          final list = ListenableBuilder(
            listenable: ctrl,
            builder: (context, _) => HerdrWorkspacesView(
              snapshot: ctrl.snapshot,
              error: ctrl.error,
              session: session,
              selectedWorkspaceId: _wide ? _selected : null,
              onBack: () => context.canPop() ? context.pop() : context.go('/hosts/$hostId'),
              onRetry: ctrl.retry,
              onOpenWorkspace: (w) => _openWorkspace(w.id),
              onCreateWorkspace: () => unawaited(createWorkspace()),
              onRenameWorkspace: renameWorkspace,
              onCloseWorkspace: closeWorkspace,
            ),
          );
          if (!_wide) return list;
          final selected = _selected;
          return Row(
            children: [
              SizedBox(width: 360, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? Center(child: Text(l.herdrPickWorkspace))
                    : ListenableBuilder(
                        listenable: ctrl,
                        builder: (context, _) => HerdrWorkspaceView(
                          workspaceId: selected,
                          snapshot: ctrl.snapshot,
                          error: ctrl.error,
                          onRetry: ctrl.retry,
                          onOpenPane: (p) => unawaited(openPane(p)),
                          onNewTerminal: (w) => unawaited(newTerminal(w)),
                          onRenameTab: renameTab,
                          onCloseTab: closeTab,
                          onStartAgent: (p) => unawaited(startAgent(p)),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
