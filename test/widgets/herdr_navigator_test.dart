import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/presentation/containers/herdr_navigator_container.dart';
import 'package:openmosh/features/hosts/presentation/views/host_detail_view.dart';
import 'package:openmosh/l10n/l10n.dart';

import '../support/fakes.dart';
import '../support/herdr_fakes.dart';
import '../support/l10n_app.dart';

void main() {
  late FakeHerdrRepository repo;
  late List<String> opened;

  setUp(() {
    repo = FakeHerdrRepository();
    opened = [];
  });

  Future<void> pump(WidgetTester t) async {
    final router = GoRouter(
      initialLocation: '/n',
      routes: [
        GoRoute(
          path: '/n',
          builder: (_, _) => const HerdrNavigatorContainer(hostId: 'h1', session: 'default'),
        ),
        GoRoute(
          path: '/agent/:id',
          builder: (_, s) {
            opened.add(s.uri.toString());
            return const Scaffold(body: Text('agent view'));
          },
        ),
      ],
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [herdrRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('shows workspaces, tabs and agents with status; blocked is highlighted', (t) async {
    await pump(t);
    expect(find.text('api'), findsOneWidget);
    expect(find.text('web'), findsOneWidget);
    expect(find.text('1  main'), findsOneWidget);
    expect(find.text('claude'), findsOneWidget);
    expect(find.text('codex'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('needs you'), findsOneWidget);
    expect(find.text('working'), findsOneWidget);
    final blocked = t.widget<Material>(find.byKey(const Key('pane-w1:p1')));
    final normal = t.widget<Material>(find.byKey(const Key('pane-w2:p1')));
    expect((blocked.shape! as RoundedRectangleBorder).side.width, 2);
    expect((normal.shape! as RoundedRectangleBorder).side, BorderSide.none);
    expect(find.text('w1:p1 · on screen'), findsOneWidget);
  });

  testWidgets('long-polls with the last revision and shows changes', (t) async {
    await pump(t);
    expect(repo.snapshotSince, [null, '0000000000000001']);
    final s = sampleSnapshot();
    repo.changeSnapshot(
      HerdrSnapshot(
        workspaces: s.workspaces.where((w) => w.id != 'w2').toList(),
        tabs: s.tabsOf('w1'),
        panes: s.panesOf('w1:t1'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('web'), findsNothing);
    expect(repo.snapshotSince.last, '0000000000000002');
  });

  testWidgets('stops polling in the background and resumes in the foreground', (t) async {
    await pump(t);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    repo.changeSnapshot(sampleSnapshot());
    await t.pumpAndSettle();
    // The call in flight finished; no new call while in the background.
    expect(repo.snapshotSince.length, 2);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pumpAndSettle();
    expect(repo.snapshotSince, [null, '0000000000000001', '0000000000000002']);
  });

  testWidgets('closing a workspace asks first and only sends after confirming', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('ws-menu-w2')));
    await t.pumpAndSettle();
    await t.tap(find.text('Close').last);
    await t.pumpAndSettle();
    expect(find.text('Close workspace web?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(repo.actions, isEmpty);

    await t.tap(find.byKey(const Key('ws-menu-w2')));
    await t.pumpAndSettle();
    await t.tap(find.text('Close').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('herdr-confirm-close')));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'workspace.close', 'id': 'w2'},
    ]);
  });

  testWidgets('closing a tab asks first', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('tab-menu-w1:t1')));
    await t.pumpAndSettle();
    await t.tap(find.text('Close').last);
    await t.pumpAndSettle();
    expect(find.text('Close tab main?'), findsOneWidget);
    await t.tap(find.byKey(const Key('herdr-confirm-close')));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'tab.close', 'id': 'w1:t1'},
    ]);
  });

  testWidgets('creates a workspace and a tab, renames a tab', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('herdr-new-workspace')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('herdr-label')), 'docs');
    await t.tap(find.byKey(const Key('herdr-label-ok')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('ws-menu-w1')));
    await t.pumpAndSettle();
    await t.tap(find.text('New tab'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('herdr-label-ok')));
    await t.pumpAndSettle();

    await t.tap(find.byKey(const Key('tab-menu-w1:t1')));
    await t.pumpAndSettle();
    await t.tap(find.text('Rename'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('herdr-label')), 'review');
    await t.tap(find.byKey(const Key('herdr-label-ok')));
    await t.pumpAndSettle();

    expect(repo.actions.map(actionJson), [
      {'op': 'workspace.create', 'label': 'docs'},
      {'op': 'tab.create', 'workspace_id': 'w1'},
      {'op': 'tab.rename', 'id': 'w1:t1', 'label': 'review'},
    ]);
  });

  testWidgets('starts an agent from the hook allowlist in a pane', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('pane-menu-w1:p2')));
    await t.pumpAndSettle();
    await t.tap(find.text('Start an agent in this pane'));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-aider')), findsNothing);
    await t.tap(find.byKey(const Key('agent-codex')));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'agent.start', 'pane_id': 'w1:p2', 'agent': 'codex'},
    ]);
  });

  testWidgets('opening a pane focuses it, then opens its graphic view', (t) async {
    await pump(t);
    await t.tap(find.text('claude'));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'pane.focus', 'id': 'w1:p1'},
    ]);
    expect(opened, ['/agent/h1?pane=w1%3Ap1&session=default']);
    expect(find.text('agent view'), findsOneWidget);
  });

  testWidgets('a failed action shows its error', (t) async {
    repo.actError = const _Fail();
    await pump(t);
    await t.tap(find.byKey(const Key('tab-menu-w1:t1')));
    await t.pumpAndSettle();
    await t.tap(find.text('Close').last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('herdr-confirm-close')));
    await t.pumpAndSettle();
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('empty session offers to create a workspace', (t) async {
    repo = FakeHerdrRepository(snapshot: const HerdrSnapshot());
    await pump(t);
    expect(find.text('This Herdr session has no workspaces.'), findsOneWidget);
    await t.tap(find.text('New workspace'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('herdr-label-ok')));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'workspace.create'},
    ]);
  });

  testWidgets('the host screen shows the navigator entry only when supported', (t) async {
    var taps = 0;
    Widget view(VoidCallback? onNav) => l10nApp(
      home: Scaffold(
        body: HostDetailView(
          host: testHost(),
          sessions: const [],
          agents: null,
          loading: false,
          onLoad: () {},
          onShell: () {},
          onAttach: (_) {},
          onEnablePush: () {},
          onHerdr: () {},
          onHerdrNavigator: onNav,
        ),
      ),
    );
    await t.pumpWidget(view(null));
    expect(find.byKey(const Key('open_herdr_navigator')), findsNothing);
    expect(find.byKey(const Key('open_herdr')), findsOneWidget);
    await t.pumpWidget(view(() => taps++));
    await t.tap(find.byKey(const Key('open_herdr_navigator')));
    expect(taps, 1);
  });
}

class _Fail implements Exception {
  const _Fail();
}
