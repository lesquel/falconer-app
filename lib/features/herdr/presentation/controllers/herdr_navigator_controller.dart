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
  Future<Object?> act(HerdrAction action) async {
    try {
      await repository.act(hostId, action, session: session);
      return null;
    } catch (e) {
      return e;
    } finally {
      if (!_disposed && !_hidden) {
        _poller
          ..start()
          ..poke();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _poller.dispose();
    super.dispose();
  }
}
