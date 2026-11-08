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
  @override
  Future<void> close() async => out.close();
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

  Future<void> pump() => Future<void>.delayed(Duration.zero).then((_) => Future<void>.delayed(Duration.zero));

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
    );
  });

  tearDown(() => runner.dispose());

  test('connects, attaches the session and streams output', () async {
    unawaited(runner.start());
    await pump();
    expect(runner.phase, TerminalPhase.connected);
    expect(shells.single.written.first, "herdr session attach 'main'\r");
    shells.single.out.add(Uint8List.fromList(utf8.encode('hello')));
    await pump();
    expect(utf8.decode(emu.fed), 'hello');
  });

  test('input and resizes are forwarded to the shell', () async {
    unawaited(runner.start());
    await pump();
    emu.inputCtrl.add('ls\r');
    emu.resizeCtrl.add((100, 30));
    await pump();
    expect(shells.single.written.last, 'ls\r');
    expect(shells.single.sizes.single, (100, 30));
  });

  test('a dropped connection reconnects with backoff and re-attaches', () async {
    unawaited(runner.start());
    await pump();
    conns.single.closed = true;
    await shells.single.out.close();
    await pump();
    await pump();
    expect(shells.length, 2);
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
}
