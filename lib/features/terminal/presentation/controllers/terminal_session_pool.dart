/// Live terminal sessions shared across screens, so a session can stay
/// connected after its screen closes ("Keep sessions connected").
library;

import 'dart:async';

/// Identifies one terminal: a host plus the Herdr/tmux session it attaches to.
String terminalSessionKey(String hostId, String? kind, String? session) =>
    '$hostId|${kind ?? ''}|${session ?? ''}';

/// Sessions kept at most; the least recently used one without a screen is
/// closed first. Each holds a shell, a scrollback buffer and an SSH channel.
const maxPooledSessions = 4;

final class TerminalSessionPool<T> {
  TerminalSessionPool({required this.close, this.capacity = maxPooledSessions});

  /// Disconnects one session.
  final Future<void> Function(T) close;
  final int capacity;

  /// Least recently used first.
  final _entries = <String, T>{};

  /// Open screens per key.
  final _screens = <String, int>{};

  /// The live session for [key], created with [create] when there is none.
  /// Marks it most recently used; may close the least recently used session
  /// without a screen to stay within [capacity].
  T obtain(String key, T Function() create) {
    final T session;
    if (_entries.containsKey(key)) {
      session = _entries.remove(key) as T;
    } else {
      session = create();
    }
    _entries[key] = session;
    _evict(keep: key);
    return session;
  }

  bool contains(String key) => _entries.containsKey(key);

  /// A screen shows the session for [key]: it is never evicted meanwhile.
  void attach(String key) => _screens[key] = (_screens[key] ?? 0) + 1;

  /// The screen for [key] closed.
  void detach(String key) {
    final n = (_screens[key] ?? 0) - 1;
    if (n > 0) {
      _screens[key] = n;
    } else {
      _screens.remove(key);
    }
  }

  bool shown(String key) => _screens.containsKey(key);

  /// Whether any session of [hostId] is still pooled.
  bool hasHost(String hostId) => _entries.keys.any((k) => k.startsWith('$hostId|'));

  /// Sessions an open screen shows.
  List<T> get shownSessions => [
    for (final e in _entries.entries)
      if (shown(e.key)) e.value,
  ];

  /// Every pooled session.
  List<T> get sessions => _entries.values.toList();

  /// Disconnects and forgets the session for [key].
  Future<void> release(String key) async {
    final e = _entries.remove(key);
    if (e != null) await close(e);
  }

  /// Disconnects every session no screen shows.
  Future<void> releaseHidden() async {
    for (final key in _entries.keys.where((k) => !shown(k)).toList()) {
      await release(key);
    }
  }

  Future<void> closeAll() async {
    final all = _entries.values.toList();
    _entries.clear();
    for (final e in all) {
      await close(e);
    }
  }

  void _evict({required String keep}) {
    while (_entries.length > capacity) {
      final victim = _entries.keys.where((k) => k != keep && !shown(k)).firstOrNull;
      if (victim == null) return;
      unawaited(release(victim));
    }
  }
}
