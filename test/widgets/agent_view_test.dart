import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/agent_view/presentation/containers/agent_view_container.dart';
import 'package:openmosh/features/agent_view/presentation/controllers/agent_view_controller.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/domain/repositories/herdr_repository.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/uploads/domain/usecases/upload_file.dart';
import 'package:openmosh/l10n/l10n.dart';
import 'package:openmosh/shared/ui/tokens/mosh_colors.dart';

import '../support/fakes.dart';
import '../support/file_source_fakes.dart';
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

  Future<void> pump(
    WidgetTester t, {
    bool fromTerminal = false,
    String? workspaceId,
    List<Override> overrides = const [],
  }) async {
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
                workspaceId: workspaceId,
                // VoiceMicButton throws in dispose when never used (voice bug).
                dictation: false,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/hosts/:id/herdr',
          builder: (_, s) {
            routes.add(s.uri.toString());
            return const Scaffold(body: Text('navigator'));
          },
          routes: [
            GoRoute(
              path: 'workspace',
              builder: (_, s) {
                routes.add(s.uri.toString());
                return const Scaffold(body: Text('workspace'));
              },
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
        overrides: [herdrRepositoryProvider.overrideWithValue(repo), ...overrides],
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
    await t.ensureVisible(find.byKey(const Key('choice-2')));
    await t.tap(find.byKey(const Key('choice-2')));
    await t.pumpAndSettle();
    final sent = repo.actions.map(actionJson).single;
    expect(sent['op'], 'pane.keys');
    expect(sent['pane_id'], 'w1:p1');
    expect(sent['keys'], isNotEmpty);
    expect((sent['keys']! as List).every(paneKeyNames.contains), isTrue);
    expect(find.text('needs you'), findsOneWidget);
  });

  testWidgets('a menu answer is sent once and the card hides until a new menu shows', (t) async {
    await pump(t);
    expect(find.byKey(const Key('agent-permission-card')), findsOneWidget);
    await t.ensureVisible(find.byKey(const Key('choice-2')));
    await t.tap(find.byKey(const Key('choice-2')));
    await t.tap(find.byKey(const Key('choice-0')), warnIfMissed: false);
    await t.pump();
    expect(repo.actions.map(actionJson), [
      {
        'op': 'pane.keys',
        'pane_id': 'w1:p1',
        'keys': ['3'],
      },
    ]);
    // Answered: the screen still shows the menu until the next read.
    expect(find.byKey(const Key('agent-permission-card')), findsNothing);

    // A different menu docks the card again.
    repo.changeScreen(
      PaneScreen(agent: 'claude', lines: fixture('claude', 'permission_edit_boxed')),
    );
    await t.pumpAndSettle();
    final button = find.byKey(const Key('choice-0'));
    expect((t.widget(button) as ButtonStyleButton).enabled, isTrue);
    await t.ensureVisible(button);
    await t.tap(button);
    await t.pump();
    expect(repo.actions, hasLength(2));
    expect(find.byKey(const Key('agent-permission-card')), findsNothing);

    repo.changeScreen(PaneScreen(agent: 'claude', lines: fixture('claude', 'plain')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-permission-card')), findsNothing);
  });

  testWidgets('the answered menu stays hidden while later reads still show it', (t) async {
    await pump(t);
    await t.ensureVisible(find.byKey(const Key('choice-0')));
    await t.tap(find.byKey(const Key('choice-0')));
    await t.pump();
    // The agent has not redrawn yet: the same menu, its cursor moved.
    final lines = fixture(
      'claude',
      'permission',
    ).map((l) => l.replaceFirst('❯ 1.', '  1.').replaceFirst('  3. No', '❯ 3. No')).toList();
    repo.changeScreen(PaneScreen(agent: 'claude', lines: lines));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-permission-card')), findsNothing);

    // Once the menu left the screen, the same menu asked again docks again.
    repo.changeScreen(PaneScreen(agent: 'claude', lines: fixture('claude', 'plain')));
    await t.pumpAndSettle();
    repo.changeScreen(PaneScreen(agent: 'claude', lines: fixture('claude', 'permission')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-permission-card')), findsOneWidget);
  });

  testWidgets('a failed answer keeps the card so it can be sent again', (t) async {
    repo.actError = Exception('offline');
    await pump(t);
    await t.ensureVisible(find.byKey(const Key('choice-0')));
    await t.tap(find.byKey(const Key('choice-0')));
    await t.pumpAndSettle();
    expect(repo.actions, hasLength(1));
    expect(find.byKey(const Key('agent-permission-card')), findsOneWidget);
    final button = find.byKey(const Key('choice-0'));
    expect((t.widget(button) as ButtonStyleButton).enabled, isTrue);
  });

  testWidgets('every key of the row presses its key in the pane', (t) async {
    await pump(t);
    for (final name in ['esc', 'up', 'down', 'tab', 'enter']) {
      repo.actions.clear();
      await t.tap(find.byKey(Key('agent-key-$name')));
      await t.pumpAndSettle();
      expect(repo.actions.map(actionJson), [
        {
          'op': 'pane.keys',
          'pane_id': 'w1:p1',
          'keys': [name],
        },
      ], reason: name);
    }
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

  testWidgets('user prompts are right-aligned accent bubbles; agent and tool are cards', (t) async {
    repo.screen = PaneScreen(agent: 'claude', lines: fixture('claude', 'conversation'));
    await pump(t);
    final user = find.byKey(const Key('text-user-0'));
    expect(user, findsOneWidget);
    expect(
      find.descendant(of: user, matching: find.text('why does the cart total ignore quantities?')),
      findsOneWidget,
    );
    final align = t.widget<Align>(find.descendant(of: user, matching: find.byType(Align)).first);
    expect(align.alignment, Alignment.centerRight);
    final bubble = t.widget<Material>(
      find.descendant(of: user, matching: find.byType(Material)).first,
    );
    expect(bubble.color, MoshColors.of(t.element(user)).accent);

    final agent = find.byKey(const Key('text-agent-1'));
    expect(agent, findsOneWidget);
    final agentAlign = t.widget<Align>(
      find.descendant(of: agent, matching: find.byType(Align)).first,
    );
    expect(agentAlign.alignment, Alignment.centerLeft);

    final tool = find.byKey(const Key('text-tool-3'));
    expect(tool, findsOneWidget);
    final code = t.widget<SelectableText>(
      find.descendant(of: tool, matching: find.byType(SelectableText)),
    );
    expect(code.style?.fontFamily, 'monospace');
  });

  testWidgets('a plain terminal opens graphic too, titled Terminal', (t) async {
    repo.screen = PaneScreen(lines: fixture('shell', 'conversation'));
    await pump(t);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.byKey(const Key('text-user-0')), findsOneWidget);
    expect(find.byKey(const Key('text-tool-1')), findsOneWidget);
    await t.enterText(find.byKey(const Key('chat-input')), 'ls -la');
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'pane.text', 'pane_id': 'w1:p1', 'text': 'ls -la', 'submit': true},
    ]);
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

  testWidgets('with something written, Enter sends it instead of an empty Enter', (t) async {
    await pump(t);
    await t.enterText(find.byKey(const Key('chat-input')), 'yes, go on');
    await t.tap(find.byKey(const Key('agent-key-enter')));
    await t.pumpAndSettle();
    expect(repo.actions.map(actionJson), [
      {'op': 'pane.text', 'pane_id': 'w1:p1', 'text': 'yes, go on', 'submit': true},
    ]);
    final input = t.widget<TextField>(find.byKey(const Key('chat-input')));
    expect(input.controller!.text, isEmpty);
  });

  testWidgets('attached files are uploaded and their paths go with the message', (t) async {
    final hosts = FakeHostRepository();
    await hosts.save(testHost());
    final connections = HostConnections(
      hosts: hosts,
      vault: FakeVault(),
      connector: FakeConnector(() => FakeConnection((_, _) => ok(null))),
    );
    final picker = OneFileSource();
    await pump(
      t,
      overrides: [
        fileSourceProvider.overrideWithValue(picker),
        uploadFileProvider.overrideWithValue(UploadFile(connections, prefix: () => 'u1')),
      ],
    );
    await t.tap(find.byTooltip('Attach images or files'));
    await t.pumpAndSettle();
    await t.tap(find.text('File'));
    await t.pumpAndSettle();
    expect(find.text('notes.txt'), findsOneWidget);
    expect(picker.discarded, 1);
    await t.enterText(find.byKey(const Key('chat-input')), 'read this');
    await t.tap(find.byTooltip('Send'));
    await t.pumpAndSettle();
    final sent = repo.actions.map(actionJson).single;
    expect(sent['op'], 'pane.text');
    expect(sent['submit'], true);
    final text = sent['text']! as String;
    expect(text, startsWith('/home/me/.openmosh/uploads/'));
    expect(text, contains('notes.txt'));
    expect(text, contains('read this'));
    expect(find.text('notes.txt'), findsNothing);
  });

  testWidgets('back from a pane opened in its workspace goes back to it', (t) async {
    await pump(t, workspaceId: 'w1');
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(routes, isEmpty);
  });

  testWidgets('opened from the terminal, back goes to the pane workspace, not the terminal', (
    t,
  ) async {
    await pump(t, fromTerminal: true, workspaceId: 'w1');
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(routes.last, '/hosts/h1/herdr/workspace?ws=w1&session=default');
    expect(find.text('workspace'), findsOneWidget);
    expect(find.text('terminal'), findsNothing);
  });

  testWidgets('opened from the terminal, the system back goes to the workspace too', (t) async {
    await pump(t, fromTerminal: true, workspaceId: 'w1');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(routes.last, '/hosts/h1/herdr/workspace?ws=w1&session=default');
  });

  testWidgets('without its workspace, back from the terminal goes to the navigator', (t) async {
    await pump(t, fromTerminal: true);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(routes.last, '/hosts/h1/herdr?session=default');
  });

  testWidgets('history: later reads are merged, earlier lines stay on screen', (t) async {
    repo.screen = const PaneScreen(lines: ['first answer', '', 'second answer', '', r'$ ']);
    await pump(t);
    expect(repo.readLines, [agentViewFirstLines, agentViewPollLines]);
    // The next read starts later: the first answer scrolled out of it.
    repo.changeScreen(const PaneScreen(lines: ['second answer', '', r'$ ls', 'a.txt', '', r'$ ']));
    await t.pumpAndSettle();
    expect(find.textContaining('first answer'), findsOneWidget);
    expect(find.textContaining('a.txt'), findsOneWidget);
    // Fewer lines than asked: the pane has nothing earlier to load.
    expect(find.byKey(const Key('agent-load-earlier')), findsNothing);
  });

  testWidgets('load earlier reads a longer stretch and adds it on top', (t) async {
    final long = [for (var i = 0; i < agentViewFirstLines; i++) 'line $i'];
    repo.screen = PaneScreen(lines: long);
    await pump(t);
    repo.screen = PaneScreen(lines: ['the very beginning', '', ...long]);
    await t.drag(find.byKey(const Key('agent-blocks')), const Offset(0, 20000));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('agent-load-earlier')), findsOneWidget);
    await t.tap(find.byKey(const Key('agent-load-earlier')));
    await t.pumpAndSettle();
    expect(repo.readLines.last, agentViewEarlierLines);
    await t.drag(find.byKey(const Key('agent-blocks')), const Offset(0, 20000));
    await t.pumpAndSettle();
    expect(find.textContaining('the very beginning'), findsOneWidget);
  });

  test('the screen is parsed once per change of what was read', () async {
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
    int? lines,
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
