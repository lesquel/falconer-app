import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/herdr_action.dart';
import '../../domain/entities/herdr_snapshot.dart';
import '../../domain/repositories/herdr_repository.dart';
import 'long_poller.dart';

/// Live Herdr snapshot of one host session, long-polled only while the
/// screen is shown ([resume]/[pause]), plus the allowlisted actions.
class HerdrNavigatorController extends ChangeNotifier {
  HerdrNavigatorController({
    required this.repository,
    required this.hostId,
    this.session,
    Duration Function(int attempt)? backoff,
  }) {
    _poller = LongPoller<HerdrSnapshot>(
      fetch: (since) =>
          repository.snapshot(hostId, session: session, since: since, waitMs: herdrLongPollMs),
      onData: (s, _) {
        snapshot = s;
        error = null;
        notifyListeners();
      },
      onError: (e) {
        error = e;
        notifyListeners();
      },
      backoff: backoff,
    );
  }

  final HerdrRepository repository;
  final String hostId;
  final String? session;
  late final LongPoller<HerdrSnapshot> _poller;

  HerdrSnapshot? snapshot;
  Object? error;
  bool _disposed = false;

  // Hidden screens never poll, even when an action finishes after hiding.
  bool _hidden = false;

  /// Whether a long-poll loop is active (the screen is shown).
  bool get polling => _poller.running;

  void resume() {
    _hidden = false;
    _poller.start();
  }

  void pause() {
    _hidden = true;
    _poller.pause();
  }

  /// Retries after an error that stopped polling.
  void retry() {
    error = null;
    notifyListeners();
    _poller
      ..start()
      ..poke();
  }

  /// Runs [action] and polls again at once. Returns the failure, if any, so
  /// the screen can show it; a stale id also refreshes the list.
  Future<Object?> act(HerdrAction action) async => (await run(action)).failure;

  /// [act] that also returns the id Herdr gave a created item.
  Future<({String? id, Object? failure})> run(HerdrAction action) async {
    try {
      return (id: await repository.act(hostId, action, session: session), failure: null);
    } catch (e) {
      return (id: null, failure: e);
    } finally {
      if (!_disposed && !_hidden) {
        _poller
          ..start()
          ..poke();
      }
    }
  }

  /// The first pane of tab [tabId] (or, without an id, of a tab of
  /// [workspaceId] not in [known]) once a snapshot shows it; null after
  /// [timeout] or when the screen goes away.
  Future<HerdrPane?> paneOfNewTab({
    required String workspaceId,
    required Set<String> known,
    String? tabId,
    Duration timeout = const Duration(seconds: 20),
  }) {
    HerdrPane? find() {
      final s = snapshot;
      if (s == null) return null;
      for (final t in s.tabsOf(workspaceId)) {
        if (tabId != null ? t.id != tabId : known.contains(t.id)) continue;
        final p = s.panesOf(t.id).firstOrNull;
        if (p != null) return p;
      }
      return null;
    }

    final now = find();
    if (now != null || _disposed) return Future.value(now);
    final done = Completer<HerdrPane?>();
    late final VoidCallback listener;
    late final Timer timer;
    void finish(HerdrPane? p) {
      if (done.isCompleted) return;
      timer.cancel();
      removeListener(listener);
      _waits.remove(finish);
      done.complete(p);
    }

    listener = () {
      final p = find();
      if (p != null) finish(p);
    };
    timer = Timer(timeout, () => finish(null));
    addListener(listener);
    _waits.add(finish);
    return done.future;
  }

  final _waits = <void Function(HerdrPane?)>{};

  @override
  void dispose() {
    _disposed = true;
    for (final w in _waits.toList()) {
      w(null);
    }
    _poller.dispose();
    super.dispose();
  }
}
