import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../agent_view/presentation/containers/agent_view_container.dart';
import '../../domain/entities/herdr_action.dart';
import '../../domain/entities/herdr_snapshot.dart';
import '../controllers/herdr_navigator_controller.dart';
import '../views/herdr_dialogs.dart';
import '../views/herdr_navigator_view.dart';

/// Route of the graphic view of one pane (full screen, outside the tabs).
String agentViewLocation(
  String hostId,
  String paneId, {
  String? session,
  bool fromTerminal = false,
}) => Uri(
  path: '/agent/$hostId',
  queryParameters: {'pane': paneId, 'session': ?session, if (fromTerminal) 'from': 'terminal'},
).toString();

/// The Herdr navigator of one host session. Long-polls only while it is the
/// visible screen and the app is in the foreground.
class HerdrNavigatorContainer extends ConsumerStatefulWidget {
  const HerdrNavigatorContainer({super.key, required this.hostId, this.session});
  final String hostId;
  final String? session;

  @override
  ConsumerState<HerdrNavigatorContainer> createState() => _HerdrNavigatorContainerState();
}

class _HerdrNavigatorContainerState extends ConsumerState<HerdrNavigatorContainer>
    with WidgetsBindingObserver {
  late final HerdrNavigatorController _ctrl;

  /// Another screen (the agent view) is on top: no polling until it pops.
  bool _covered = false;

  /// Tablet split view: the list and the selected pane side by side.
  bool _wide = false;
  String? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = HerdrNavigatorController(
      repository: ref.read(herdrRepositoryProvider),
      hostId: widget.hostId,
      session: widget.session,
    )..resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_covered) _ctrl.resume();
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        _ctrl.pause();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  void _show(Object? failure) {
    if (failure == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.failureText(failure))));
  }

  Future<void> _act(HerdrAction Function() build) async {
    final HerdrAction action;
    try {
      action = build();
    } catch (e) {
      _show(e);
      return;
    }
    _show(await _ctrl.act(action));
  }

  /// Focuses the pane on the computer, then opens its graphic view.
  Future<void> _open(HerdrPane p) async {
    _show(await _ctrl.act(HerdrAction.paneFocus(p.id)));
    if (!mounted) return;
    if (_wide) {
      setState(() => _selected = p.id);
      return;
    }
    _covered = true;
    _ctrl.pause();
    await context.push(agentViewLocation(widget.hostId, p.id, session: widget.session));
    _covered = false;
    if (mounted) _ctrl.resume();
  }

  Future<void> _createWorkspace() async {
    final l = context.l10n;
    final name = await askHerdrLabel(
      context,
      title: l.herdrNewWorkspace,
      action: l.herdrCreate,
      optional: true,
    );
    if (name == null) return;
    await _act(() => HerdrAction.workspaceCreate(name.isEmpty ? null : name));
  }

  Future<void> _createTab(HerdrWorkspace w) async {
    final l = context.l10n;
    final name = await askHerdrLabel(
      context,
      title: l.herdrNewTab,
      action: l.herdrCreate,
      optional: true,
    );
    if (name == null) return;
    await _act(() => HerdrAction.tabCreate(w.id, name.isEmpty ? null : name));
  }

  Future<void> _rename(String current, HerdrAction Function(String) build) async {
    final l = context.l10n;
    final name = await askHerdrLabel(
      context,
      title: l.herdrRename,
      action: l.save,
      initial: current,
    );
    if (name == null || name.isEmpty) return;
    await _act(() => build(name));
  }

  Future<void> _close(String title, HerdrAction Function() build) async {
    if (!await confirmHerdrClose(context, title)) return;
    await _act(build);
  }

  Future<void> _startAgent(HerdrPane p) async {
    final agent = await pickHerdrAgent(context);
    if (agent == null) return;
    await _act(() => HerdrAction.agentStart(p.id, agent));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) => HerdrNavigatorView(
        selectedPaneId: _wide ? _selected : null,
        snapshot: _ctrl.snapshot,
        error: _ctrl.error,
        session: widget.session,
        onBack: () => context.canPop() ? context.pop() : context.go('/hosts/${widget.hostId}'),
        onRetry: _ctrl.retry,
        onOpenPane: (p) => unawaited(_open(p)),
        onCreateWorkspace: () => unawaited(_createWorkspace()),
        onRenameWorkspace: (w) =>
            unawaited(_rename(w.label, (n) => HerdrAction.workspaceRename(w.id, n))),
        onCloseWorkspace: (w) => unawaited(
          _close(l.herdrCloseWorkspaceTitle(w.label), () => HerdrAction.workspaceClose(w.id)),
        ),
        onCreateTab: (w) => unawaited(_createTab(w)),
        onRenameTab: (t) => unawaited(_rename(t.label, (n) => HerdrAction.tabRename(t.id, n))),
        onCloseTab: (t) =>
            unawaited(_close(l.herdrCloseTabTitle(t.label), () => HerdrAction.tabClose(t.id))),
        onStartAgent: (p) => unawaited(_startAgent(p)),
      ),
    );
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          _wide = box.maxWidth >= herdrSplitWidth;
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
                        hostId: widget.hostId,
                        paneId: selected,
                        session: widget.session,
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

/// Width from which the navigator and the agent view sit side by side.
const herdrSplitWidth = 840.0;
