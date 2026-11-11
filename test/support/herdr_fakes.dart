import 'dart:async';

import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/domain/repositories/herdr_repository.dart';

/// Two workspaces; `w1:p1` is a Claude agent waiting on the user.
HerdrSnapshot sampleSnapshot() => const HerdrSnapshot(
  workspaces: [
    HerdrWorkspace(id: 'w1', label: 'api', focused: true),
    HerdrWorkspace(id: 'w2', label: 'web'),
  ],
  tabs: [
    HerdrTab(
      id: 'w1:t1',
      workspaceId: 'w1',
      label: 'main',
      number: 1,
      status: HerdrStatus.blocked,
      paneCount: 2,
      focused: true,
    ),
    HerdrTab(id: 'w2:t1', workspaceId: 'w2', label: 'dev', number: 1, status: HerdrStatus.done),
  ],
  panes: [
    HerdrPane(
      id: 'w1:p1',
      tabId: 'w1:t1',
      workspaceId: 'w1',
      agent: 'claude',
      status: HerdrStatus.blocked,
      focused: true,
    ),
    HerdrPane(id: 'w1:p2', tabId: 'w1:t1', workspaceId: 'w1'),
    HerdrPane(
      id: 'w2:p1',
      tabId: 'w2:t1',
      workspaceId: 'w2',
      agent: 'codex',
      status: HerdrStatus.working,
    ),
  ],
);

/// In-memory Herdr: answers the first call at once, then holds long-polls
/// until [changeSnapshot]/[changeScreen].
class FakeHerdrRepository implements HerdrRepository {
  FakeHerdrRepository({HerdrSnapshot? snapshot, PaneScreen? screen})
    : snap = snapshot ?? sampleSnapshot(),
      screen = screen ?? const PaneScreen();

  HerdrSnapshot snap;
  PaneScreen screen;
  bool supported = true;
  Object? actError;

  /// Id the next actions return (`tab.create` → the new tab id).
  String? actId;
  Object? snapshotError;
  final List<HerdrAction> actions = [];
  final List<String?> snapshotSince = [];
  final List<String?> readSince = [];
  final List<String> readPanes = [];
  final List<int?> readLines = [];
  int _snapRev = 1;
  int _screenRev = 1;
  // Created by the waiting call, so they belong to the test's zone.
  Completer<void>? _snapChange;
  Completer<void>? _screenChange;

  static String _rev(int n) => n.toRadixString(16).padLeft(16, '0');

  void changeSnapshot(HerdrSnapshot s) {
    snap = s;
    _snapRev++;
    final c = _snapChange;
    _snapChange = null;
    c?.complete();
  }

  void changeScreen(PaneScreen s) {
    screen = s;
    _screenRev++;
    final c = _screenChange;
    _screenChange = null;
    c?.complete();
  }

  @override
  Future<bool> supportsHerdr(String hostId) async => supported;

  @override
  Future<Polled<HerdrSnapshot>> snapshot(
    String hostId, {
    String? session,
    String? since,
    int waitMs = 0,
  }) async {
    snapshotSince.add(since);
    if (snapshotError != null) throw snapshotError!;
    if (since == _rev(_snapRev)) await (_snapChange ??= Completer<void>()).future;
    return Polled(_rev(_snapRev), false, snap);
  }

  @override
  Future<Polled<PaneScreen>> read(
    String hostId,
    String paneId, {
    String? session,
    String? since,
    int waitMs = 0,
    int? lines,
  }) async {
    readPanes.add(paneId);
    readLines.add(lines);
    readSince.add(since);
    if (since == _rev(_screenRev)) await (_screenChange ??= Completer<void>()).future;
    return Polled(_rev(_screenRev), false, screen);
  }

  @override
  Future<String?> act(String hostId, HerdrAction action, {String? session}) async {
    actions.add(action);
    if (actError != null) throw actError!;
    return actId;
  }
}

/// `op` plus fields, for compact expectations.
Map<String, Object?> actionJson(HerdrAction a) => {'op': a.op, ...a.fields};
