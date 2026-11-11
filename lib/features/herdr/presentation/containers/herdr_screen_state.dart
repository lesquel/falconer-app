import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/entities/herdr_action.dart';
import '../../domain/entities/herdr_snapshot.dart';
import '../controllers/herdr_navigator_controller.dart';
import '../views/herdr_dialogs.dart';

/// Route of the graphic view of one pane (full screen, outside the tabs).
/// [workspaceId] is where back leads (the workspace's terminals).
String agentViewLocation(
  String hostId,
  String paneId, {
  String? session,
  String? workspaceId,
  bool fromTerminal = false,
}) => Uri(
  path: '/agent/$hostId',
  queryParameters: {
    'pane': paneId,
    'session': ?session,
    'ws': ?workspaceId,
    if (fromTerminal) 'from': 'terminal',
  },
).toString();

/// Width from which a Herdr screen shows two panels side by side.
const herdrSplitWidth = 840.0;

/// What both Herdr screens share: one long-poll loop that runs only while
/// the screen is visible and the app in the foreground, the allowlisted
/// actions with their dialogs, and opening a pane in the graphic view.
abstract class HerdrScreenState<T extends ConsumerStatefulWidget> extends ConsumerState<T>
    with WidgetsBindingObserver {
  String get hostId;
  String? get session;

  late final HerdrNavigatorController ctrl;

  /// Another screen is on top: no polling until it pops.
  bool _covered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ctrl = HerdrNavigatorController(
      repository: ref.read(herdrRepositoryProvider),
      hostId: hostId,
      session: session,
    )..resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_covered) ctrl.resume();
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        ctrl.pause();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ctrl.dispose();
    super.dispose();
  }

  void show(Object? failure) {
    if (failure == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.failureText(failure))));
  }

  /// Pushes [location] and pauses polling until it pops.
  Future<void> pushCovering(String location) async {
    _covered = true;
    ctrl.pause();
    await context.push(location);
    _covered = false;
    if (mounted) ctrl.resume();
  }

  Future<void> act(HerdrAction Function() build) async {
    final HerdrAction action;
    try {
      action = build();
    } catch (e) {
      show(e);
      return;
    }
    show(await ctrl.act(action));
  }

  /// Shows the pane: in [embed] when the screen has room for it, else full
  /// screen. No pane.focus here: it would move what the computer shows; the
  /// graphic view reads and writes by pane id, and only terminal mode focuses.
  Future<void> openPane(HerdrPane p, {ValueChanged<String>? embed}) async {
    if (embed != null) {
      embed(p.id);
      return;
    }
    await pushCovering(
      agentViewLocation(hostId, p.id, session: session, workspaceId: p.workspaceId),
    );
  }

  /// Opens a new tab (a shell) in [w], then its pane once Herdr shows it.
  Future<void> newTerminal(HerdrWorkspace w, {ValueChanged<String>? embed}) async {
    final known = {for (final t in ctrl.snapshot?.tabsOf(w.id) ?? <HerdrTab>[]) t.id};
    final r = await ctrl.run(HerdrAction.tabCreate(w.id));
    show(r.failure);
    if (r.failure != null || !mounted) return;
    final pane = await ctrl.paneOfNewTab(workspaceId: w.id, known: known, tabId: r.id);
    if (pane != null && mounted) await openPane(pane, embed: embed);
  }

  Future<void> createWorkspace() async {
    final l = context.l10n;
    final name = await askHerdrLabel(
      context,
      title: l.herdrNewWorkspace,
      action: l.herdrCreate,
      optional: true,
    );
    if (name == null) return;
    await act(() => HerdrAction.workspaceCreate(name.isEmpty ? null : name));
  }

  Future<void> rename(String current, HerdrAction Function(String) build) async {
    final l = context.l10n;
    final name = await askHerdrLabel(
      context,
      title: l.herdrRename,
      action: l.save,
      initial: current,
    );
    if (name == null || name.isEmpty) return;
    await act(() => build(name));
  }

  Future<void> close(String title, HerdrAction Function() build) async {
    if (!await confirmHerdrClose(context, title)) return;
    await act(build);
  }

  Future<void> startAgent(HerdrPane p) async {
    final agent = await pickHerdrAgent(context);
    if (agent == null) return;
    await act(() => HerdrAction.agentStart(p.id, agent));
  }

  void renameWorkspace(HerdrWorkspace w) =>
      unawaited(rename(w.label, (n) => HerdrAction.workspaceRename(w.id, n)));

  void closeWorkspace(HerdrWorkspace w) => unawaited(
    close(context.l10n.herdrCloseWorkspaceTitle(w.label), () => HerdrAction.workspaceClose(w.id)),
  );

  void renameTab(HerdrTab t) => unawaited(rename(t.label, (n) => HerdrAction.tabRename(t.id, n)));

  void closeTab(HerdrTab t) =>
      unawaited(close(context.l10n.herdrCloseTabTitle(t.label), () => HerdrAction.tabClose(t.id)));
}
