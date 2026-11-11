import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/herdr/presentation/containers/herdr_navigator_container.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/lock/domain/user_presence.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/uploads/domain/repositories/file_source.dart';
import 'package:openmosh/features/terminal/presentation/containers/terminal_container.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session_pool.dart';
import 'package:openmosh/l10n/l10n.dart';

import '../features/hosts/paired_devices_test.dart' show ScriptedAuth;
import '../features/terminal/terminal_runner_test.dart' show FakeShell, ShellConnection;
import '../support/fakes.dart';
import '../support/file_source_fakes.dart';
import '../support/herdr_fakes.dart';

/// The two modes (S1): the normal terminal stays as it is, and a Herdr
/// terminal can switch to the graphic view of the focused pane.
void main() {
  late HostConnections connections;
  late TerminalSessionPool<TerminalSession> pool;
  late FakeHerdrRepository repo;
  late List<String> routes;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
    final hosts = FakeHostRepository();
    await hosts.save(testHost());
    final shells = <FakeShell>[];
    connections = HostConnections(
      hosts: hosts,
      vault: FakeVault(),
      connector: FakeConnector(() => ShellConnection(shells)),
    );
    pool = TerminalSessionPool<TerminalSession>(close: (s) => s.dispose());
    repo = FakeHerdrRepository();
    routes = [];
  });

  /// Herdr terminals type their attach command on a timer; let it run out.
  Future<void> close(WidgetTester t) async {
    await t.pumpWidget(const SizedBox.shrink());
    await t.pump(const Duration(seconds: 10));
  }

  Future<void> open(WidgetTester t, String location, {FileSource? files}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, _) =>
              TextButton(onPressed: () => c.push(location), child: const Text('home')),
        ),
        GoRoute(
          path: '/terminal/:id',
          builder: (_, s) => TerminalContainer(
            hostId: s.pathParameters['id']!,
            session: s.uri.queryParameters['session'],
            kind: s.uri.queryParameters['kind'],
            fromAgentView: s.uri.queryParameters['from'] == 'agent',
          ),
        ),
        GoRoute(
          path: '/agent/:id',
          builder: (_, s) {
            routes.add(s.uri.toString());
            return const Scaffold(body: Text('agent view'));
          },
        ),
      ],
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          userPresenceProvider.overrideWithValue(
            UserPresence(inner: ScriptedAuth(), elapsed: () async => const Duration(hours: 1)),
          ),
          terminalSessionPoolProvider.overrideWithValue(pool),
          hostConnectionsProvider.overrideWithValue(connections),
          herdrRepositoryProvider.overrideWithValue(repo),
          if (files != null) fileSourceProvider.overrideWithValue(files),
          settingsProvider.overrideWith((ref) => Stream.value(const AppSettings())),
          hostProvider.overrideWith((ref, id) => Stream.value(testHost())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
        ),
      ),
    );
    await t.tap(find.text('home'));
    for (var i = 0; i < 4; i++) {
      await t.pump();
    }
  }

  testWidgets('a plain shell is unchanged: Open Herdr is there, no graphic mode', (t) async {
    await open(t, '/terminal/h1');
    expect(find.byKey(const Key('switch_to_herdr')), findsOneWidget);
    expect(find.byKey(const Key('switch_to_graphic')), findsNothing);
  });

  testWidgets('a Herdr terminal without the navigator protocol stays terminal only', (t) async {
    repo.supported = false;
    await open(t, '/terminal/h1?session=default&kind=herdr');
    expect(find.byKey(const Key('switch_to_herdr')), findsNothing);
    expect(find.byKey(const Key('switch_to_graphic')), findsNothing);
    await close(t);
  });

  testWidgets('a Herdr terminal opens the graphic view of the focused pane', (t) async {
    await open(t, '/terminal/h1?session=default&kind=herdr');
    await t.tap(find.byKey(const Key('switch_to_graphic')));
    await t.pump();
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(routes, [
      agentViewLocation('h1', 'w1:p1', session: 'default', workspaceId: 'w1', fromTerminal: true),
    ]);
    // `ws`: back from the graphic view goes to the pane's workspace.
    expect(routes.single, '/agent/h1?pane=w1%3Ap1&session=default&ws=w1&from=terminal');
    await close(t);
  });

  testWidgets('opened from the graphic view, the graphic mode goes back to it', (t) async {
    await open(t, '/terminal/h1?session=default&kind=herdr&from=agent');
    await t.tap(find.byKey(const Key('switch_to_graphic')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(routes, isEmpty);
    expect(find.text('home'), findsOneWidget);
    await close(t);
  });

  testWidgets('the terminal chat still attaches an uploaded file', (t) async {
    final picker = OneFileSource();
    await open(t, '/terminal/h1', files: picker);
    await t.tap(find.byTooltip('Chat'));
    await t.pump();
    await t.tap(find.byTooltip('Attach images or files'));
    await t.pumpAndSettle();
    await t.tap(find.text('File'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('notes.txt'), findsOneWidget);
    expect(picker.discarded, 1);
  });
}
