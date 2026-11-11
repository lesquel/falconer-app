import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n.dart';
import '../../../agent_view/presentation/containers/agent_view_container.dart';
import '../views/herdr_workspace_view.dart';
import 'herdr_screen_state.dart';

/// Route of screen 2 (one workspace's terminals).
String herdrWorkspaceLocation(String hostId, String workspaceId, {String? session}) => Uri(
  path: '/hosts/$hostId/herdr/workspace',
  queryParameters: {'ws': workspaceId, 'session': ?session},
).toString();

/// Screen 2 of the Herdr navigator: the tabs and panes of one workspace.
/// Every pane, agent or plain terminal, opens in the graphic view; on a
/// tablet beside the list.
class HerdrWorkspaceContainer extends ConsumerStatefulWidget {
  const HerdrWorkspaceContainer({
    super.key,
    required this.hostId,
    required this.workspaceId,
    this.session,
  });
  final String hostId;
  final String workspaceId;
  final String? session;

  @override
  ConsumerState<HerdrWorkspaceContainer> createState() => _HerdrWorkspaceContainerState();
}

class _HerdrWorkspaceContainerState extends HerdrScreenState<HerdrWorkspaceContainer> {
  @override
  String get hostId => widget.hostId;
  @override
  String? get session => widget.session;

  bool _wide = false;
  String? _selected;

  ValueChanged<String>? get _embed => _wide ? (id) => setState(() => _selected = id) : null;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          _wide = box.maxWidth >= herdrSplitWidth;
          final list = ListenableBuilder(
            listenable: ctrl,
            builder: (context, _) => HerdrWorkspaceView(
              workspaceId: widget.workspaceId,
              snapshot: ctrl.snapshot,
              error: ctrl.error,
              session: session,
              selectedPaneId: _wide ? _selected : null,
              onBack: () => context.canPop()
                  ? context.pop()
                  : context.go(
                      Uri(
                        path: '/hosts/$hostId/herdr',
                        queryParameters: {'session': ?session},
                      ).toString(),
                    ),
              onRetry: ctrl.retry,
              onOpenPane: (p) => unawaited(openPane(p, embed: _embed)),
              onNewTerminal: (w) => unawaited(newTerminal(w, embed: _embed)),
              onRenameTab: renameTab,
              onCloseTab: closeTab,
              onStartAgent: (p) => unawaited(startAgent(p)),
            ),
          );
          final selected = _selected;
          if (!_wide) return list;
          return Row(
            children: [
              SizedBox(width: 400, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? Center(child: Text(l.herdrPickPane))
                    : AgentViewContainer(
                        key: ValueKey(selected),
                        hostId: hostId,
                        paneId: selected,
                        session: session,
                        embedded: true,
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
