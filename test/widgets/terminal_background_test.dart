import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/lock/domain/user_presence.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/terminal/domain/usecases/terminal_runner.dart';
import 'package:openmosh/features/terminal/presentation/containers/terminal_container.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session_pool.dart';
import 'package:openmosh/l10n/l10n.dart';
import 'package:xterm/xterm.dart';

import '../features/hosts/paired_devices_test.dart' show ScriptedAuth;
import '../features/terminal/terminal_runner_test.dart' show FakeShell, ShellConnection;
import '../support/fakes.dart';

void main() {
  late ScriptedAuth auth;
  late Duration t;
  late UserPresence presence;
  late TerminalSessionPool<TerminalSession> pool;
  late HostConnections connections;
  late List<FakeShell> shells;
  late List<ShellConnection> conns;

  setUp(() async {
    // The network-regained stream of the terminal screen.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/connectivity_status'),
      (_) async => null,
    );
    auth = ScriptedAuth();
    t = const Duration(hours: 1);
    presence = UserPresence(inner: auth, elapsed: () async => t);
    final repo = FakeHostRepository();
    await repo.save(testHost());
    shells = [];
    conns = [];
    connections = HostConnections(
      hosts: repo,
      vault: FakeVault(),
      connector: FakeConnector(() {
        final c = ShellConnection(shells);
        conns.add(c);
        return c;
      }),
    );
    pool = TerminalSessionPool<TerminalSession>(close: (s) => s.dispose());
  });

  Future<void> open(WidgetTester tester, {bool keepConnected = true}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, _) => TextButton(onPressed: () => c.push('/t'), child: const Text('home')),
          routes: [GoRoute(path: 't', builder: (_, _) => const TerminalContainer(hostId: 'h1'))],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPresenceProvider.overrideWithValue(presence),
          terminalSessionPoolProvider.overrideWithValue(pool),
          hostConnectionsProvider.overrideWithValue(connections),
          settingsProvider.overrideWith(
            (ref) => Stream.value(AppSettings(keepConnected: keepConnected)),
          ),
          hostProvider.overrideWith((ref, id) => Stream.value(testHost())),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
        ),
      ),
    );
    await tester.tap(find.text('home'));
    await tester.pump();
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a terminal suspended in the background reconnects after re-verification', (
    tester,
  ) async {
    await open(tester);
    expect(shells, hasLength(1));
    final session = pool.sessions.single;
    expect(session.runner.phase, TerminalPhase.connected);

    // Ten minutes in the background: the lifecycle suspends it.
    await session.runner.suspend();
    await connections.disconnectAll();
    await tester.pump();
    t += const Duration(minutes: 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump();
    expect(auth.reasons, hasLength(1), reason: 'the open terminal asks again');
    expect(shells, hasLength(2));
    expect(conns, hasLength(2));
    expect(session.runner.phase, TerminalPhase.connected);
    expect(find.byType(TerminalView), findsOneWidget);
  });

  testWidgets('without keep connected, closing the last terminal closes its SSH connection', (
    tester,
  ) async {
    await open(tester, keepConnected: false);
    expect(shells, hasLength(1));
    GoRouter.of(tester.element(find.byType(TerminalContainer))).pop();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 1));
    expect(pool.sessions, isEmpty);
    expect(conns.single.isClosed, isTrue);
  });

  testWidgets('with keep connected, the session and its connection stay open', (tester) async {
    await open(tester);
    GoRouter.of(tester.element(find.byType(TerminalContainer))).pop();
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(seconds: 1));
    expect(pool.sessions, hasLength(1));
    expect(conns.single.isClosed, isFalse);
    await tester.runAsync(pool.closeAll);
  });
}
