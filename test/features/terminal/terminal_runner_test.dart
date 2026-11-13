import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/terminal/domain/entities/backoff_policy.dart';
import 'package:openmosh/features/terminal/domain/repositories/terminal_emulator.dart';
import 'package:openmosh/features/terminal/domain/usecases/terminal_runner.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ssh/domain/ssh_ports.dart';

import '../../support/fakes.dart';

class FakeEmulator implements TerminalEmulator {
  final fed = <int>[];
  final notices = <String>[];
  var resets = 0;
  @override
  void reset() => resets++;
  final inputCtrl = StreamController<String>.broadcast();
  final resizeCtrl = StreamController<(int, int)>.broadcast();
  @override
  int get cols => 80;
  @override
  int get rows => 24;
  @override
  void feed(List<int> bytes) => fed.addAll(bytes);
  @override
  void notice(String text) => notices.add(text);
  @override
  Stream<String> get input => inputCtrl.stream;
  @override
  Stream<(int, int)> get resizes => resizeCtrl.stream;
}

class FakeShell implements ShellChannel {
  final out = StreamController<Uint8List>();
  final written = <String>[];
  final sizes = <(int, int)>[];
  @override
  Stream<Uint8List> get output => out.stream;
  @override
  Future<void> write(List<int> data) async => written.add(utf8.decode(data));
  @override
  Future<void> resize(int c, int r) async => sizes.add((c, r));

  /// Like the Rust shell, closing does not wait for the reader to drain.
  @override
  Future<void> close() async => unawaited(out.close());
}

class ShellConnection extends FakeConnection {
  ShellConnection(this.shells) : super((_, _) => ok(null));
  final List<FakeShell> shells;
  @override
  Future<ShellChannel> openShell({required int cols, required int rows}) async {
    final s = FakeShell();
    shells.add(s);
    return s;
  }
}

void main() {
  late FakeHostRepository hosts;
  late FakeVault vault;
  late FakeConnector connector;
  late List<FakeShell> shells;
  late List<ShellConnection> conns;
  late FakeEmulator emu;
  late List<Duration> sleeps;
  late TerminalRunner runner;

  Future<void> pump() =>
      Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

  setUp(() async {
    hosts = FakeHostRepository();
    await hosts.save(testHost());
    vault = FakeVault();
    shells = [];
    conns = [];
    connector = FakeConnector(() {
      final c = ShellConnection(shells);
      conns.add(c);
      return c;
    });
    emu = FakeEmulator();
    sleeps = [];
    runner = TerminalRunner(
      hostId: 'h1',
      connections: HostConnections(hosts: hosts, vault: vault, connector: connector),
      emulator: emu,
      attachCommand: "herdr session attach 'main'",
      backoff: BackoffPolicy(random: () => 0),
      sleep: (d) async => sleeps.add(d),
      attachFallback: const Duration(milliseconds: 10),
    );
  });

  tearDown(() => runner.dispose());

  test('connects, attaches the session once the shell prints, and streams output', () async {
    unawaited(runner.start());
    await pump();
    expect(runner.phase, TerminalPhase.connected);
    expect(shells.single.written, isEmpty, reason: 'waits for the shell prompt');
    shells.single.out.add(Uint8List.fromList(utf8.encode('\$ ')));
    await pump();
    expect(shells.single.written.first, "herdr session attach 'main'\r");
    shells.single.out.add(Uint8List.fromList(utf8.encode('hello')));
    await pump();
    expect(utf8.decode(emu.fed), r'$ hello');
  });

  test('a silent shell still gets the attach command after a short wait', () async {
    unawaited(runner.start());
    await pump();
    expect(shells.single.written, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(shells.single.written.first, "herdr session attach 'main'\r");
    expect(emu.resets, 0, reason: 'the first connection keeps the screen');
  });

  test('input and resizes are forwarded to the shell', () async {
    unawaited(runner.start());
    await pump();
    emu.inputCtrl.add('ls\r');
    emu.resizeCtrl.add((100, 30));
    await pump();
    await Future<void>.delayed(resizeDebounce * 2);
    expect(shells.single.written, contains('ls\r'));
    expect(shells.single.sizes.single, (100, 30));
  });

  test('a dropped connection reconnects with backoff and re-attaches', () async {
    unawaited(runner.start());
    await pump();
    conns.single.closed = true;
    conns.single.closeReason = 'Connection reset by peer';
    await shells.single.out.close();
    await pump();
    await pump();
    expect(shells.length, 2);
    expect(emu.resets, 1, reason: "the old session's screen is cleared before re-attaching");
    expect(emu.notices, contains('[connection lost: Connection reset by peer — reconnecting…]'));
    expect(shells.last.written, isEmpty);
    shells.last.out.add(Uint8List.fromList(utf8.encode('\$ ')));
    await pump();
    expect(shells.last.written.first, "herdr session attach 'main'\r");
    expect(sleeps.first, const Duration(milliseconds: 500));
    expect(vault.unlocks, 2, reason: 'a new connection unlocks the key again');
  });

  test('shell exit on a live connection ends the session without reconnecting', () async {
    unawaited(runner.start());
    await pump();
    await shells.single.out.close();
    await pump();
    expect(runner.phase, TerminalPhase.closed);
    expect(shells.length, 1);
  });

  test('host key mismatch is fatal: no retry, no override', () async {
    connector.fail = const HostKeyMismatchFailure(expected: 'SHA256:a', actual: 'SHA256:b');
    await runner.start();
    expect(runner.phase, TerminalPhase.failed);
    expect(runner.failure, isA<HostKeyMismatchFailure>());
    expect(sleeps, isEmpty);
  });

  test('an unanswered SSH key is fatal: no retry', () async {
    connector.fail = const AuthTimeoutFailure();
    await runner.start();
    expect(runner.phase, TerminalPhase.failed);
    expect(runner.failure, isA<AuthTimeoutFailure>());
    expect(sleeps, isEmpty);
  });

  test('transient failures back off 0.5, 1, 2 s', () async {
    var n = 0;
    connector.make = () {
      n++;
      if (n < 4) throw const ConnectionFailure();
      final c = ShellConnection(shells);
      conns.add(c);
      return c;
    };
    unawaited(runner.start());
    for (var i = 0; i < 10; i++) {
      await pump();
    }
    expect(sleeps.take(3).map((d) => d.inMilliseconds), [500, 1000, 2000]);
    expect(runner.phase, TerminalPhase.connected);
  });

  test('resizes are debounced: 30 in 100 ms send one resize with the last size', () async {
    unawaited(runner.start());
    await pump();
    for (var i = 0; i < 30; i++) {
      emu.resizeCtrl.add((80 + i, 24));
      await Future<void>.delayed(const Duration(microseconds: 3333));
    }
    expect(shells.single.sizes, isEmpty, reason: 'the size is still changing');
    await Future<void>.delayed(resizeDebounce * 2);
    expect(shells.single.sizes, [(109, 24)]);
  });

  test('while paused, a failed connection waits for resume instead of retrying', () async {
    connector.fail = const ConnectionFailure();
    runner.paused = true;
    unawaited(runner.start());
    for (var i = 0; i < 10; i++) {
      await pump();
    }
    expect(connector.endpoints, hasLength(1), reason: 'no retry while paused');
    expect(sleeps, isEmpty);
    expect(runner.phase, TerminalPhase.reconnecting);

    connector.fail = null;
    runner.paused = false;
    await pump();
    await pump();
    expect(connector.endpoints, hasLength(2), reason: 'resume retries at once');
    expect(runner.phase, TerminalPhase.connected);
  });

  test('network regained retries a paused runner once', () async {
    connector.fail = const ConnectionFailure();
    runner.paused = true;
    unawaited(runner.start());
    await pump();
    runner.wake();
    for (var i = 0; i < 10; i++) {
      await pump();
    }
    expect(connector.endpoints, hasLength(2));
    expect(sleeps, isEmpty);
  });

  test('suspend closes the shell and stops; a restart reconnects on a clean screen', () async {
    unawaited(runner.start());
    await pump();
    expect(runner.phase, TerminalPhase.connected);
    await runner.suspend();
    conns.single.closed = true;
    await pump();
    await pump();
    expect(runner.suspended, isTrue);
    expect(runner.phase, TerminalPhase.idle);
    expect(shells, hasLength(1), reason: 'no reconnect while suspended');
    expect(sleeps, isEmpty);

    runner.wake();
    await pump();
    expect(shells, hasLength(1), reason: 'a plain wake (network) does not restart it');

    runner.wake(restart: true);
    await pump();
    await pump();
    expect(shells, hasLength(2));
    expect(runner.suspended, isFalse);
    expect(runner.phase, TerminalPhase.connected);
    expect(emu.resets, 1, reason: 'the suspended screen is cleared before re-attaching');
  });

  test('a restart asked while a suspend is still winding down is not lost', () async {
    unawaited(runner.start());
    await pump();
    final suspending = runner.suspend();
    runner.wake(restart: true);
    await suspending;
    for (var i = 0; i < 4; i++) {
      await pump();
    }
    expect(shells, hasLength(2), reason: 'a new shell after the restart');
    expect(runner.phase, TerminalPhase.connected);
  });
}
