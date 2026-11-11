import 'package:flutter/foundation.dart';

import '../../../herdr/domain/entities/herdr_action.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../herdr/domain/repositories/herdr_repository.dart';
import '../../../herdr/presentation/controllers/long_poller.dart';
import '../../domain/entities/screen_block.dart';
import '../../domain/usecases/parse_agent_screen.dart';
import '../../domain/usecases/screen_history.dart';

/// Lines of the first read, of each long-poll after it (merged into what
/// was already read) and of "load earlier". `HookCommand.herdrRead` still
/// accepts at most 400; the hook reads up to 2000.
const agentViewFirstLines = 400;
const agentViewPollLines = 300;
const agentViewEarlierLines = 400;

/// One pane's screen, long-polled while shown. Every read is merged into
/// the history seen while the screen is open, and parsed into blocks only
/// when that history changed (never during build).
class AgentViewController extends ChangeNotifier {
  AgentViewController({
    required this.repository,
    required this.hostId,
    required this.paneId,
    this.session,
    Duration Function(int attempt)? backoff,
  }) {
    _poller = LongPoller<PaneScreen>(
      fetch: (since) => repository.read(
        hostId,
        paneId,
        session: session,
        since: since,
        waitMs: herdrLongPollMs,
        lines: _asked = since == null ? agentViewFirstLines : agentViewPollLines,
      ),
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
  final _history = ScreenHistory();
  int _asked = agentViewFirstLines;
  bool _disposed = false;

  /// A "load earlier" read is in flight.
  bool loadingEarlier = false;

  /// A read returned fewer lines than asked: the pane has nothing earlier.
  bool historyComplete = false;

  /// Times the screen was parsed (one per change of the history).
  @visibleForTesting
  int parses = 0;

  /// Everything read of the pane while the screen is open.
  List<String> get history => _history.lines;

  void _onScreen(PaneScreen s, String rev) {
    error = null;
    _apply(s, requested: _asked);
    notifyListeners();
  }

  void _apply(PaneScreen s, {required int requested}) {
    if (s.lines.length < requested) historyComplete = true;
    final changed = _history.merge(s.lines, requested: requested);
    if (changed || s.agent != screen?.agent || screen == null) {
      blocks = parseAgentScreen(s.agent, _history.lines);
      parses++;
    }
    screen = s;
  }

  /// Reads a longer stretch of the pane and adds what came before.
  Future<Object?> loadEarlier() async {
    if (loadingEarlier || _disposed) return null;
    loadingEarlier = true;
    notifyListeners();
    try {
      final r = await repository.read(
        hostId,
        paneId,
        session: session,
        lines: agentViewEarlierLines,
      );
      final body = r.body;
      if (!_disposed && body != null) _apply(body, requested: agentViewEarlierLines);
      return null;
    } catch (e) {
      return e;
    } finally {
      loadingEarlier = false;
      if (!_disposed) notifyListeners();
    }
  }

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
