import 'package:flutter/foundation.dart';

import '../../../herdr/domain/entities/herdr_action.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../herdr/domain/repositories/herdr_repository.dart';
import '../../../herdr/presentation/controllers/long_poller.dart';
import '../../domain/entities/screen_block.dart';
import '../../domain/usecases/parse_agent_screen.dart';

/// One pane's screen, long-polled while shown and parsed into blocks once
/// per new revision (never during build).
class AgentViewController extends ChangeNotifier {
  AgentViewController({
    required this.repository,
    required this.hostId,
    required this.paneId,
    this.session,
    Duration Function(int attempt)? backoff,
  }) {
    _poller = LongPoller<PaneScreen>(
      fetch: (since) =>
          repository.read(hostId, paneId, session: session, since: since, waitMs: herdrLongPollMs),
      onData: _onScreen,
      onError: (e) {
        error = e;
        notifyListeners();
      },
      backoff: backoff,
    );
  }

  final HerdrRepository repository;
  final String hostId;
  final String paneId;
  final String? session;
  late final LongPoller<PaneScreen> _poller;

  PaneScreen? screen;
  List<ScreenBlock> blocks = const [];
  Object? error;
  String? _parsedRev;
  bool _disposed = false;

  /// Times the screen was parsed (one per revision).
  @visibleForTesting
  int parses = 0;

  void _onScreen(PaneScreen s, String rev) {
    error = null;
    if (rev != _parsedRev) {
      _parsedRev = rev;
      blocks = parseAgentScreen(s.agent, s.lines);
      parses++;
    }
    screen = s;
    notifyListeners();
  }

  void resume() => _poller.start();
  void pause() => _poller.pause();

  void retry() {
    error = null;
    notifyListeners();
    _poller
      ..start()
      ..poke();
  }

  /// Presses [keys] in the pane (a menu answer).
  Future<Object?> sendKeys(List<String> keys) => _act(() => HerdrAction.paneKeys(paneId, keys));

  /// Types [text] into the agent and submits it.
  Future<Object?> sendText(String text) => _act(() => HerdrAction.paneText(paneId, text));

  /// Brings the pane to the front on the computer (before the terminal mode).
  Future<Object?> focus() => _act(() => HerdrAction.paneFocus(paneId));

  Future<Object?> _act(HerdrAction Function() build) async {
    try {
      await repository.act(hostId, build(), session: session);
      return null;
    } catch (e) {
      return e;
    } finally {
      if (!_disposed) {
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
