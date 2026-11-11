import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../terminal/presentation/views/chat_composer.dart';
import '../../../voice/presentation/containers/voice_mic_button.dart';
import '../controllers/agent_view_controller.dart';
import '../views/agent_screen_view.dart';

/// The existing terminal on this Herdr session (the other mode).
String herdrTerminalLocation(String hostId, String? session, {bool fromAgentView = false}) => Uri(
  path: '/terminal/$hostId',
  queryParameters: {
    'session': session ?? 'default',
    'kind': 'herdr',
    if (fromAgentView) 'from': 'agent',
  },
).toString();

/// Graphic mode of one Herdr pane. Long-polls only while visible and in the
/// foreground; [embedded] drops the back button (tablet split view).
class AgentViewContainer extends ConsumerStatefulWidget {
  const AgentViewContainer({
    super.key,
    required this.hostId,
    required this.paneId,
    this.session,
    this.fromTerminal = false,
    this.embedded = false,
    this.dictation = true,
  });

  final String hostId;
  final String paneId;
  final String? session;

  /// Opened from the terminal: the terminal mode goes back instead of
  /// stacking a second terminal.
  final bool fromTerminal;
  final bool embedded;

  /// Shows the dictation mic in the composer.
  final bool dictation;

  @override
  ConsumerState<AgentViewContainer> createState() => _AgentViewContainerState();
}

class _AgentViewContainerState extends ConsumerState<AgentViewContainer>
    with WidgetsBindingObserver {
  late final AgentViewController _ctrl;
  bool _covered = false;
  bool _sending = false;
  String _draft = '';

  /// Rebuilds the composer with [_draft] (after a failed send).
  int _composerGen = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ctrl = AgentViewController(
      repository: ref.read(herdrRepositoryProvider),
      hostId: widget.hostId,
      paneId: widget.paneId,
      session: widget.session,
    )..resume();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_covered) _ctrl.resume();
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        _ctrl.pause();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  void _show(Object? failure) {
    if (failure == null || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(context.l10n.failureText(failure))));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _sending = true);
    final failure = await _ctrl.sendText(text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      // The composer cleared itself; a failed send gets its text back.
      if (failure != null) {
        _draft = text;
        _composerGen++;
      }
    });
    _show(failure);
  }

  /// Focuses the pane on the computer, then shows it in the terminal.
  Future<void> _terminalMode() async {
    _show(await _ctrl.focus());
    if (!mounted) return;
    if (widget.fromTerminal) {
      context.pop();
      return;
    }
    _covered = true;
    _ctrl.pause();
    await context.push(herdrTerminalLocation(widget.hostId, widget.session, fromAgentView: true));
    _covered = false;
    if (mounted) _ctrl.resume();
  }

  @override
  Widget build(BuildContext context) {
    final view = ListenableBuilder(
      listenable: _ctrl,
      builder: (context, _) {
        final screen = _ctrl.screen;
        return AgentScreenView(
          // A pane without an agent is a plain terminal.
          title: screen == null ? widget.paneId : screen.agent ?? context.l10n.herdrShellPane,
          status: screen?.status ?? HerdrStatus.unknown,
          blocks: _ctrl.blocks,
          loaded: screen != null,
          error: _ctrl.error,
          onRetry: _ctrl.retry,
          onKeys: (keys) async => _show(await _ctrl.sendKeys(keys)),
          onTerminalMode: () => unawaited(_terminalMode()),
          onBack: widget.embedded
              ? null
              : () =>
                    context.canPop() ? context.pop() : context.go('/hosts/${widget.hostId}/herdr'),
          composer: ChatComposer(
            key: ValueKey(_composerGen),
            initialText: _draft,
            attachments: const [],
            busy: _sending,
            autofocus: false,
            onChanged: (t) => _draft = t,
            onSend: (t) => unawaited(_send(t)),
            onAttach: null,
            onRemoveAttachment: (_) {},
            onClose: null,
            micBuilder: widget.dictation ? (insert) => VoiceMicButton(onTranscript: insert) : null,
          ),
        );
      },
    );
    return widget.embedded ? view : Scaffold(body: view);
  }
}
