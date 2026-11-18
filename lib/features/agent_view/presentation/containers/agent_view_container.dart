import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../herdr/presentation/containers/herdr_workspace_container.dart';
import '../../../terminal/presentation/containers/chat_attachments_flow.dart';
import '../../../terminal/presentation/controllers/chat_attachment.dart';
import '../../../terminal/presentation/controllers/terminal_session.dart' show withAttachmentLines;
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

/// Where back from the graphic view of a pane leads: its workspace's
/// terminals, or the navigator when the workspace is unknown. Never a
/// terminal.
String agentViewBackLocation(String hostId, {String? session, String? workspaceId}) =>
    workspaceId != null
    ? herdrWorkspaceLocation(hostId, workspaceId, session: session)
    : Uri(path: '/hosts/$hostId/herdr', queryParameters: {'session': ?session}).toString();

/// Graphic mode of one Herdr pane. Long-polls only while visible and in the
/// foreground; [embedded] drops the back button (tablet split view).
class AgentViewContainer extends ConsumerStatefulWidget {
  const AgentViewContainer({
    super.key,
    required this.hostId,
    required this.paneId,
    this.session,
    this.workspaceId,
    this.fromTerminal = false,
    this.embedded = false,
    this.dictation = true,
  });

  final String hostId;
  final String paneId;
  final String? session;

  /// The pane's workspace: back leads to its terminals.
  final String? workspaceId;

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
  bool _uploading = false;
  String _draft = '';
  final _attachments = <ChatAttachment>[];

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

  /// Sends [text] with the attached files' paths (uploaded already), then
  /// Enter, through `pane.text`.
  Future<void> _send(String text) async {
    final files = [for (final a in _attachments) a.remotePath];
    if (text.trim().isEmpty && files.isEmpty) return;
    final sent = List.of(_attachments);
    setState(() {
      _sending = true;
      _attachments.clear();
    });
    final message = files.isEmpty ? text : '${files.join(' ')} ${withAttachmentLines(text, files)}';
    final failure = await _ctrl.sendText(message);
    if (!mounted) return;
    setState(() {
      _sending = false;
      // The composer cleared itself; a failed send gets its text back.
      if (failure != null) {
        _draft = text;
        _attachments.insertAll(0, sent);
        _composerGen++;
      }
    });
    _show(failure);
  }

  /// ↵ sends what is written in the composer; with nothing written it
  /// presses Enter in the pane.
  Future<void> _enter() async {
    if (_draft.trim().isNotEmpty || _attachments.isNotEmpty) {
      final text = _draft;
      setState(() {
        _draft = '';
        _composerGen++;
      });
      await _send(text);
      return;
    }
    _show(await _ctrl.sendKeys(const ['enter']));
  }

  Future<void> _attach() async {
    final images = await askAttachmentKind(context);
    if (images == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final files = await uploadAttachments(context, ref, widget.hostId, images: images);
      if (mounted) setState(() => _attachments.addAll(files));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _loadEarlier() async => _show(await _ctrl.loadEarlier());

  /// Back to the workspace (or navigator) the pane belongs to. Opened from
  /// a terminal, the terminal is not where it goes back to: the stack is
  /// replaced by the workspace's.
  void _back() {
    if (!widget.fromTerminal && context.canPop()) {
      context.pop();
      return;
    }
    context.go(
      agentViewBackLocation(
        widget.hostId,
        session: widget.session,
        workspaceId: widget.workspaceId,
      ),
    );
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
          subtitle: widget.session,
          status: screen?.status ?? HerdrStatus.unknown,
          blocks: _ctrl.blocks,
          loaded: screen != null,
          error: _ctrl.error,
          onRetry: _ctrl.retry,
          onKeys: (keys) async => _show(await _ctrl.sendKeys(keys)),
          onChoice: (keys) async {
            final failure = await _ctrl.choose(keys);
            _show(failure);
            return failure;
          },
          onTerminalMode: () => unawaited(_terminalMode()),
          onBack: widget.embedded ? null : _back,
          onEnter: () => unawaited(_enter()),
          onLoadEarlier: _ctrl.historyComplete ? null : () => unawaited(_loadEarlier()),
          loadingEarlier: _ctrl.loadingEarlier,
          composer: ChatComposer(
            key: ValueKey(_composerGen),
            initialText: _draft,
            attachments: List.unmodifiable(_attachments),
            busy: _sending || _uploading,
            autofocus: false,
            compact: true,
            onChanged: (t) => _draft = t,
            onSend: (t) => unawaited(_send(t)),
            onAttach: () => unawaited(_attach()),
            onRemoveAttachment: (i) => setState(() => _attachments.removeAt(i)),
            onClose: null,
            micBuilder: widget.dictation ? (insert) => VoiceMicButton(onTranscript: insert) : null,
          ),
        );
      },
    );
    if (widget.embedded) return view;
    // The system back gesture goes where the back button goes.
    return PopScope(
      canPop: !widget.fromTerminal,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(body: view),
    );
  }
}
