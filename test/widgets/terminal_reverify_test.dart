import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/lock/domain/user_presence.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/terminal/presentation/containers/terminal_container.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session_pool.dart';
import 'package:openmosh/l10n/l10n.dart';
import 'package:xterm/xterm.dart';

import '../features/hosts/paired_devices_test.dart' show ScriptedAuth;
import '../support/fakes.dart';

void main() {
  late ScriptedAuth auth;
  late Duration t;
  late UserPresence presence;
  late TerminalSessionPool<TerminalSession> pool;
  late HostConnections connections;

  setUp(() async {
    auth = ScriptedAuth();
    t = const Duration(hours: 1);
    presence = UserPresence(inner: auth, elapsed: () async => t);
    final repo = FakeHostRepository();
    await repo.save(testHost());
    connections = HostConnections(
      hosts: repo,
      vault: FakeVault(),
      connector: FakeConnector(() => FakeConnection((_, _) => ok(utf8.encode('')))),
    );
    pool = TerminalSessionPool<TerminalSession>(close: (s) => s.dispose());
    // A session left connected by an earlier screen.
    pool.obtain(
      terminalSessionKey('h1', null, null),
      () => TerminalSession.create(hostId: 'h1', connections: connections),
    );
  });

  Future<void> open(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (c, _) => TextButton(onPressed: () => c.push('/t'), child: const Text('home')),
          routes: [
            GoRoute(
              path: 't',
              builder: (_, _) => const TerminalContainer(hostId: 'h1'),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPresenceProvider.overrideWithValue(presence),
          terminalSessionPoolProvider.overrideWithValue(pool),
          hostConnectionsProvider.overrideWithValue(connections),
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
    await tester.tap(find.text('home'));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('a pooled shell is not shown when the user refuses verification', (tester) async {
    auth.allow = false;
    await open(tester);
    await tester.pumpAndSettle();
    expect(auth.reasons, ["Verify it's you to show the open terminal"]);
    expect(find.byType(TerminalView), findsNothing);
    expect(find.text('home'), findsOneWidget, reason: 'went back');
  });

  testWidgets('a pooled shell shows after verification', (tester) async {
    await open(tester);
    await tester.pump();
    expect(auth.reasons, hasLength(1));
    expect(find.byType(TerminalView), findsOneWidget);
  });

  testWidgets('a recent verification opens the pooled shell without asking', (tester) async {
    presence.markVerified();
    t += const Duration(minutes: 2);
    await open(tester);
    await tester.pump();
    expect(auth.reasons, isEmpty);
    expect(find.byType(TerminalView), findsOneWidget);
  });

  testWidgets('returning to an open terminal after 5 minutes asks again', (tester) async {
    await open(tester);
    await tester.pump();
    expect(auth.reasons, hasLength(1));
    // Back from the background soon: no prompt.
    t += const Duration(minutes: 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(auth.reasons, hasLength(1));
    // Back after a long while, and the user refuses: the terminal closes.
    t += const Duration(minutes: 10);
    auth.allow = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(auth.reasons, hasLength(2));
    expect(find.byType(TerminalView), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });
}
