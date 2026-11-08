import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/data/datasources/xterm_emulator.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session_pool.dart';

void main() {
  late List<String> closed;
  late TerminalSessionPool<String> pool;

  setUp(() {
    closed = [];
    pool = TerminalSessionPool<String>(close: (s) async => closed.add(s));
  });

  test('the same key returns the same live session', () {
    var created = 0;
    final a = pool.obtain('h1|herdr|main', () => 'S${++created}');
    final b = pool.obtain('h1|herdr|main', () => 'S${++created}');
    expect(a, 'S1');
    expect(b, 'S1');
    expect(created, 1);
  });

  test('release closes and forgets a session; the next obtain creates a new one', () async {
    pool.obtain('k', () => 'old');
    await pool.release('k');
    expect(closed, ['old']);
    expect(pool.contains('k'), isFalse);
    expect(pool.obtain('k', () => 'new'), 'new');
  });

  test('closeAll closes every session', () async {
    pool.obtain('a', () => 'A');
    pool.obtain('b', () => 'B');
    await pool.closeAll();
    expect(closed, unorderedEquals(['A', 'B']));
    expect(pool.contains('a'), isFalse);
  });

  test('key separates hosts and sessions', () {
    expect(terminalSessionKey('h1', null, null), isNot(terminalSessionKey('h1', 'herdr', 'main')));
    expect(terminalSessionKey('h1', 'tmux', 'a'), isNot(terminalSessionKey('h2', 'tmux', 'a')));
  });

  test('keeps at most 4 sessions, closing the least recently used first', () async {
    for (final k in ['a', 'b', 'c', 'd']) {
      pool.obtain(k, () => k.toUpperCase());
    }
    pool.obtain('a', () => 'unused'); // a is now the most recently used
    pool.obtain('e', () => 'E');
    await Future<void>.delayed(Duration.zero);
    expect(closed, ['B']);
    expect(pool.sessions, ['C', 'D', 'A', 'E']);
  });

  test('a session an open screen shows is never evicted', () async {
    for (final k in ['a', 'b', 'c', 'd']) {
      pool.obtain(k, () => k.toUpperCase());
      pool.attach(k);
    }
    pool.obtain('e', () => 'E');
    await Future<void>.delayed(Duration.zero);
    expect(closed, isEmpty, reason: 'every older session is on screen');
    pool.detach('b');
    pool.obtain('f', () => 'F');
    await Future<void>.delayed(Duration.zero);
    expect(closed, ['B', 'E']);
    expect(pool.sessions, ['A', 'C', 'D', 'F']);
  });

  test('releaseHidden closes only sessions without a screen', () async {
    pool.obtain('a', () => 'A');
    pool.obtain('b', () => 'B');
    pool.attach('a');
    await pool.releaseHidden();
    expect(closed, ['B']);
    expect(pool.shownSessions, ['A']);
  });

  test('hasHost tells whether a host still has a pooled session', () async {
    pool.obtain(terminalSessionKey('h1', 'herdr', 'main'), () => 'A');
    expect(pool.hasHost('h1'), isTrue);
    expect(pool.hasHost('h2'), isFalse);
    await pool.release(terminalSessionKey('h1', 'herdr', 'main'));
    expect(pool.hasHost('h1'), isFalse);
  });

  test('the terminal keeps 3000 lines of scrollback', () {
    expect(XtermEmulator().terminal.maxLines, 3000);
  });
}
