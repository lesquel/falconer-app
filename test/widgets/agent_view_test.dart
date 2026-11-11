import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/agent_view/presentation/containers/agent_view_container.dart';
import 'package:openmosh/features/agent_view/presentation/controllers/agent_view_controller.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/domain/repositories/herdr_repository.dart';
import 'package:openmosh/l10n/l10n.dart';

import '../support/herdr_fakes.dart';

List<String> fixture(String agent, String name) =>
    File('test/features/agent_view/fixtures/$agent/$name.txt').readAsLinesSync();

void main() {
  late FakeHerdrRepository repo;
  late List<String> routes;

  setUp(() {
    repo = FakeHerdrRepository(
      screen: PaneScreen(
        agent: 'claude',
        status: HerdrStatus.blocked,
        lines: fixture('claude', 'permission'),
      ),
    );
    routes = [];
  });

  Future<void> pump(WidgetTester t, {bool fromTerminal = false}) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (c, _) => TextButton(onPressed: () => c.push('/a'), child: const Text('home')),
          routes: [
            GoRoute(
              path: 'a',
              builder: (_, _) => AgentViewContainer(
                hostId: 'h1',
                paneId: 'w1:p1',
                session: 'default',
                fromTerminal: fromTerminal,
                // VoiceMicButton throws in dispose when never used (voice bug).
                dictation: false,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/terminal/:id',
          builder: (_, s) {
            routes.add(s.uri.toString());
            return const Scaffold(body: Text('terminal'));
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
    await t.tap(find.text('home'));
    await t.pumpAndSettle();
  }

  testWidgets('a menu becomes buttons that press the option keys', (t) async {
    await pump(t);
    expect(find.text('Do you want to proceed?'), findsOneWidget);
    expect(find.byKey(const Key('choice-block-0')), findsNothing);
    expect(find.byKey(const Key('choice-0')), findsOneWidget);
    expect(find.byKey(const Key('choice-2')), findsOneWidget);
    await t.tap(find.byKey(const Key('choice-2')));
    await t.pumpAndSettle();
    final sent = repo.actions.map(actionJson).single;
    expect(sent['op'], 'pane.keys');
    expect(sent['pane_id'], 'w1:p1');
    expect(sent['keys'], isNotEmpty);
    expect((sent['keys']! as List).every(paneKeyNames.contains), isTrue);
    expect(find.text('needs you'), findsOneWidget);
  });

  testWidgets('the composer types into the agent and submits', (t) async {
    await pump(t);
    await t.enterText(find.byKey(const Key('chat-input')), 'run the tests');
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'pane.text', 'pane_id': 'w1:p1', 'text': 'run the tests', 'submit': true},
    ]);
  });

  testWidgets('an unrecognized screen is shown only as text', (t) async {
    repo.screen = const PaneScreen(
      agent: 'mystery',
      lines: ['Continue? maybe', '  1. something', '  2. other'],
    );
    await pump(t);
    expect(find.byKey(const Key('choice-0')), findsNothing);
    expect(find.textContaining('Continue? maybe'), findsOneWidget);
  });

  testWidgets('new screens arrive by long-poll', (t) async {
    await pump(t);
    expect(repo.readSince, [null, '0000000000000001']);
    repo.changeScreen(PaneScreen(agent: 'claude', lines: fixture('claude', 'plain')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('choice-0')), findsNothing);
    expect(find.textContaining('small online shop'), findsOneWidget);
  });

  testWidgets('terminal mode focuses the pane, then opens the Herdr terminal', (t) async {
    await pump(t);
    await t.tap(find.byKey(const Key('agent-terminal-mode')));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'pane.focus', 'id': 'w1:p1'},
    ]);
    expect(routes, ['/terminal/h1?session=default&kind=herdr&from=agent']);
  });

  testWidgets('opened from the terminal, terminal mode goes back to it', (t) async {
    await pump(t, fromTerminal: true);
    await t.tap(find.byKey(const Key('agent-terminal-mode')));
    await t.pumpAndSettle();
    expect(routes, isEmpty);
    expect(find.text('home'), findsOneWidget);
  });

  test('the screen is parsed once per revision', () async {
    final same = _SameRevRepository();
    final ctrl = AgentViewController(
      repository: same,
      hostId: 'h1',
      paneId: 'w1:p1',
      backoff: (_) => Duration.zero,
    )..resume();
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    ctrl.dispose();
    expect(same.reads, 4);
    expect(ctrl.parses, 1);
  });
}

/// Answers every read with the same revision and a body.
class _SameRevRepository implements HerdrRepository {
  int reads = 0;

  @override
  Future<Polled<PaneScreen>> read(
    String hostId,
    String paneId, {
    String? session,
    String? since,
    int waitMs = 0,
  }) async {
    reads++;
    // Three answers, then a long-poll that never returns.
    if (reads > 3) await Completer<void>().future;
    await Future<void>.delayed(Duration.zero);
    return const Polled('aaaaaaaaaaaaaaaa', false, PaneScreen(lines: ['hello']));
  }

  @override
  Future<String?> act(String hostId, HerdrAction action, {String? session}) async => null;

  @override
  Future<Polled<HerdrSnapshot>> snapshot(
    String hostId, {
    String? session,
    String? since,
    int waitMs = 0,
  }) => throw UnimplementedError();

  @override
  Future<bool> supportsHerdr(String hostId) async => true;
}
