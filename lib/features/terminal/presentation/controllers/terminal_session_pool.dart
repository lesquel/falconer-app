/// Live terminal sessions shared across screens, so a session can stay
/// connected after its screen closes ("Keep sessions connected").
library;

/// Identifies one terminal: a host plus the Herdr/tmux session it attaches to.
String terminalSessionKey(String hostId, String? kind, String? session) =>
    '$hostId|${kind ?? ''}|${session ?? ''}';

final class TerminalSessionPool<T> {
  TerminalSessionPool({required this.close});

  /// Disconnects one session.
  final Future<void> Function(T) close;
  final _entries = <String, T>{};

  /// The live session for [key], created with [create] when there is none.
  T obtain(String key, T Function() create) => _entries.putIfAbsent(key, create);

  bool contains(String key) => _entries.containsKey(key);

  /// Disconnects and forgets the session for [key].
  Future<void> release(String key) async {
    final e = _entries.remove(key);
    if (e != null) await close(e);
  }

  Future<void> closeAll() async {
    final all = _entries.values.toList();
    _entries.clear();
    for (final e in all) {
      await close(e);
    }
  }
}
