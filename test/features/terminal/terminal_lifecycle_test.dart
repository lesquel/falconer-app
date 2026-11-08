import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/terminal/domain/usecases/terminal_runner.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_lifecycle.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session_pool.dart';

import '../../support/fakes.dart';
import 'terminal_runner_test.dart' show FakeShell, ShellConnection;

class FakeTimer implements Timer {
  FakeTimer(this.duration, this.callback);
  final Duration duration;
  final void Function() callback;
  bool cancelled = false;
  void fire() {
    if (!cancelled) callback();
  }

  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

void main() {
  late List<FakeShell> shells;
  late List<ShellConnection> conns;
  late HostConnections connections;
  late TerminalSessionPool<TerminalSession> pool;
  late List<FakeTimer> timers;
  late TerminalLifecycle lifecycle;
  late List<TerminalSession> disposed;

  Future<void> pump() async {
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    shells = [];
    conns = [];
    final hosts = FakeHostRepository();
    await hosts.save(testHost());
    connections = HostConnections(
      hosts: hosts,
      vault: FakeVault(),
      connector: FakeConnector(() {
        final c = ShellConnection(shells);
        conns.add(c);
        return c;
      }),
    );
    disposed = [];
    pool = TerminalSessionPool<TerminalSession>(
      close: (s) async {
        disposed.add(s);
        await s.dispose();
      },
    );
    timers = [];
    lifecycle = TerminalLifecycle(
      pool: pool,
      disconnectAll: connections.disconnectAll,
      timer: (d, f) {
        final t = FakeTimer(d, f);
        timers.add(t);
        return t;
      },
    );
  });

  TerminalSession open(String session, {bool onScreen = true}) {
    final key = terminalSessionKey('h1', 'herdr', session);
    final s = pool.obtain(
      key,
      () => TerminalSession.create(
        hostId: 'h1',
        connections: connections,
        session: session,
        kind: 'herdr',
      ),
    );
    if (onScreen) pool.attach(key);
    unawaited(s.runner.start());
    return s;
  }

  test('pausing stops retries; resuming before 10 minutes keeps everything open', () async {
    final s = open('main');
    await pump();
    lifecycle.paused();
    expect(s.runner.paused, isTrue);
    expect(timers.single.duration, const Duration(minutes: 10));

    lifecycle.resumed();
    expect(timers.single.cancelled, isTrue);
    expect(s.runner.paused, isFalse);
    timers.single.fire();
    await pump();
    expect(conns.single.isClosed, isFalse);
    expect(s.runner.phase, TerminalPhase.connected);
  });

  test('after 10 minutes in the background every shell and connection closes', () async {
    final shown = open('main');
    final hidden = open('other', onScreen: false);
    await pump();
    expect(shells, hasLength(2));

    lifecycle.paused();
    timers.single.fire();
    await pump();
    expect(disposed, [hidden], reason: 'a session without a screen is released');
    expect(pool.sessions, [shown]);
    expect(shown.runner.suspended, isTrue);
    expect(conns.single.isClosed, isTrue);
    expect(connections.isConnected('h1'), isFalse);
    expect(shells, hasLength(2), reason: 'nothing reconnects in the background');

    lifecycle.resumed();
    await pump();
    expect(shells, hasLength(2), reason: 'the screen reconnects after verifying the user');
    shown.runner.wake(restart: true);
    await pump();
    expect(shells, hasLength(3));
    expect(conns, hasLength(2), reason: 'a new SSH connection');
    expect(shown.runner.phase, TerminalPhase.connected);
  });
}
