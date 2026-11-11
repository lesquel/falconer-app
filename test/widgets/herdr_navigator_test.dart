import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/presentation/containers/herdr_navigator_container.dart';
import 'package:openmosh/features/herdr/presentation/containers/herdr_workspace_container.dart';
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

  Future<void> pump(WidgetTester t, {String at = '/hosts/h1/herdr?session=default'}) async {
    final router = GoRouter(
      initialLocation: at,
      routes: [
        GoRoute(
          path: '/hosts/:id/herdr',
          builder: (_, s) => HerdrNavigatorContainer(
            hostId: s.pathParameters['id']!,
            session: s.uri.queryParameters['session'],
          ),
          routes: [
            GoRoute(
              path: 'workspace',
              builder: (_, s) => HerdrWorkspaceContainer(
                hostId: s.pathParameters['id']!,
                workspaceId: s.uri.queryParameters['ws']!,
                session: s.uri.queryParameters['session'],
              ),
            ),
          ],
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

  Future<void> openWorkspace(WidgetTester t, String label) async {
    await t.tap(find.text(label));
    await t.pumpAndSettle();
  }

  group('host screen', () {
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

    testWidgets('View as agents sits in the main open group with Herdr and Shell', (t) async {
      var taps = 0;
      await t.pumpWidget(view(() => taps++));
      final group = find.byKey(const Key('host-open-group'));
      expect(group, findsOneWidget);
      for (final k in ['open_herdr', 'open_herdr_navigator', 'open_shell']) {
        expect(
          find.descendant(of: group, matching: find.byKey(Key(k))),
          findsOneWidget,
          reason: k,
        );
      }
      expect(find.descendant(of: group, matching: find.text('View as agents')), findsOneWidget);
      final herdr = t.getSize(find.byKey(const Key('open_herdr')));
      final agents = t.getSize(find.byKey(const Key('open_herdr_navigator')));
      expect(agents.height, herdr.height);
      // Same row as Herdr, not below it.
      expect(
        t.getTopLeft(find.byKey(const Key('open_herdr_navigator'))).dy,
        t.getTopLeft(find.byKey(const Key('open_herdr'))).dy,
      );
      await t.tap(find.byKey(const Key('open_herdr_navigator')));
      expect(taps, 1);
    });

    testWidgets('View as agents is hidden without the herdr protocol', (t) async {
      await t.pumpWidget(view(null));
      expect(find.byKey(const Key('open_herdr_navigator')), findsNothing);
      expect(find.text('View as agents'), findsNothing);
      expect(find.byKey(const Key('open_herdr')), findsOneWidget);
      expect(find.byKey(const Key('open_shell')), findsOneWidget);
    });
  });

  group('workspaces screen', () {
    testWidgets('lists workspaces with counts, needs-you badge and focus; no panes', (t) async {
      await pump(t);
      expect(find.text('api'), findsOneWidget);
      expect(find.text('web'), findsOneWidget);
      expect(find.text('1 agent · 1 terminal'), findsOneWidget);
      expect(find.text('1 agent'), findsOneWidget);
      final api = find.byKey(const Key('ws-w1'));
      final web = find.byKey(const Key('ws-w2'));
      expect(find.descendant(of: api, matching: find.text('needs you')), findsOneWidget);
      expect(find.descendant(of: web, matching: find.text('needs you')), findsNothing);
      expect(find.descendant(of: api, matching: find.text('on screen')), findsOneWidget);
      // Panes live on the workspace screen.
      expect(find.text('claude'), findsNothing);
      expect(find.text('Terminal'), findsNothing);
    });

    testWidgets('tapping a workspace opens its detail', (t) async {
      await pump(t);
      await openWorkspace(t, 'api');
      expect(find.text('claude'), findsOneWidget);
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('1  main'), findsOneWidget);
      expect(find.text('codex'), findsNothing);
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
      expect(repo.snapshotSince.length, 2);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(repo.snapshotSince, [null, '0000000000000001', '0000000000000002']);
    });

    testWidgets('only the visible screen polls: one call per change with detail open', (t) async {
      await pump(t);
      await openWorkspace(t, 'api');
      repo.changeSnapshot(sampleSnapshot());
      await t.pumpAndSettle();
      final before = repo.snapshotSince.length;
      repo.changeSnapshot(sampleSnapshot());
      await t.pumpAndSettle();
      expect(repo.snapshotSince.length, before + 1);
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

    testWidgets('creates and renames a workspace', (t) async {
      await pump(t);
      await t.tap(find.byKey(const Key('herdr-new-workspace')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('herdr-label')), 'docs');
      await t.tap(find.byKey(const Key('herdr-label-ok')));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('ws-menu-w1')));
      await t.pumpAndSettle();
      await t.tap(find.text('Rename'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('herdr-label')), 'backend');
      await t.tap(find.byKey(const Key('herdr-label-ok')));
      await t.pumpAndSettle();

      expect(repo.actions.map(actionJson), [
        {'op': 'workspace.create', 'label': 'docs'},
        {'op': 'workspace.rename', 'id': 'w1', 'label': 'backend'},
      ]);
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

    testWidgets('a failed action shows its error', (t) async {
      repo.actError = const _Fail();
      await pump(t);
      await t.tap(find.byKey(const Key('ws-menu-w2')));
      await t.pumpAndSettle();
      await t.tap(find.text('Close').last);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('herdr-confirm-close')));
      await t.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('workspace screen', () {
    const at = '/hosts/h1/herdr/workspace?ws=w1&session=default';

    testWidgets('lists agents with status and plain terminals', (t) async {
      await pump(t, at: at);
      expect(find.text('api'), findsOneWidget);
      expect(find.text('claude'), findsOneWidget);
      expect(find.text('needs you'), findsOneWidget);
      expect(find.text('Terminal'), findsOneWidget);
      final blocked = t.widget<Material>(find.byKey(const Key('pane-w1:p1')));
      final plain = t.widget<Material>(find.byKey(const Key('pane-w1:p2')));
      expect((blocked.shape! as RoundedRectangleBorder).side.width, 2);
      expect((plain.shape! as RoundedRectangleBorder).side, BorderSide.none);
    });

    testWidgets('an agent pane focuses it, then opens its graphic view', (t) async {
      await pump(t, at: at);
      await t.tap(find.text('claude'));
      await t.pumpAndSettle();
      expect(repo.actions.map(actionJson), [
        {'op': 'pane.focus', 'id': 'w1:p1'},
      ]);
      expect(opened, ['/agent/h1?pane=w1%3Ap1&session=default']);
    });

    testWidgets('a plain terminal opens in the graphic view too', (t) async {
      await pump(t, at: at);
      await t.tap(find.text('Terminal'));
      await t.pumpAndSettle();
      expect(opened, ['/agent/h1?pane=w1%3Ap2&session=default']);
      expect(find.text('agent view'), findsOneWidget);
    });

    testWidgets('New terminal creates a tab here, then opens its pane once it appears', (t) async {
      repo.actId = 'w1:t2';
      await pump(t, at: at);
      await t.tap(find.byKey(const Key('herdr-new-terminal')));
      await t.pumpAndSettle();
      expect(repo.actions.map(actionJson), [
        {'op': 'tab.create', 'workspace_id': 'w1'},
      ]);
      expect(opened, isEmpty);
      final s = sampleSnapshot();
      repo.changeSnapshot(
        HerdrSnapshot(
          workspaces: s.workspaces,
          tabs: [
            ...s.tabs,
            const HerdrTab(id: 'w1:t2', workspaceId: 'w1', label: 'zsh', number: 2),
          ],
          panes: [
            ...s.panes,
            const HerdrPane(id: 'w1:p3', tabId: 'w1:t2', workspaceId: 'w1'),
          ],
        ),
      );
      await t.pumpAndSettle();
      expect(opened, ['/agent/h1?pane=w1%3Ap3&session=default']);
    });

    testWidgets('closing a tab asks first; renaming sends the new label', (t) async {
      await pump(t, at: at);
      await t.tap(find.byKey(const Key('tab-menu-w1:t1')));
      await t.pumpAndSettle();
      await t.tap(find.text('Rename'));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('herdr-label')), 'review');
      await t.tap(find.byKey(const Key('herdr-label-ok')));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const Key('tab-menu-w1:t1')));
      await t.pumpAndSettle();
      await t.tap(find.text('Close').last);
      await t.pumpAndSettle();
      expect(find.text('Close tab main?'), findsOneWidget);
      await t.tap(find.byKey(const Key('herdr-confirm-close')));
      await t.pumpAndSettle();
      expect(repo.actions.map(actionJson), [
        {'op': 'tab.rename', 'id': 'w1:t1', 'label': 'review'},
        {'op': 'tab.close', 'id': 'w1:t1'},
      ]);
    });

    testWidgets('starts an agent from the hook allowlist in a pane', (t) async {
      await pump(t, at: at);
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

    testWidgets('a closed workspace says so', (t) async {
      await pump(t, at: '/hosts/h1/herdr/workspace?ws=w9&session=default');
      expect(find.text('This workspace is no longer open.'), findsOneWidget);
    });
  });
}

class _Fail implements Exception {
  const _Fail();
}
