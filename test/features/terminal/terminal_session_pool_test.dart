import 'package:flutter_test/flutter_test.dart';
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
}
