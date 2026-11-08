import 'package:flutter/foundation.dart';

import '../../../hosts/domain/usecases/host_connections.dart';
import '../../../keyboard/domain/entities/modifier_state.dart';
import '../../../sessions/domain/entities/remote_session.dart';
import '../../data/datasources/xterm_emulator.dart';
import '../../domain/usecases/terminal_runner.dart';
import 'chat_attachment.dart';

/// One terminal: emulator, connection runner and sticky modifier state.
/// Lives in the session pool so it can outlive its screen.
/// Time an agent needs to turn a pasted image path into an attachment
/// before Enter. Claude Code reads the file asynchronously; an Enter that
/// arrives first submits the text and leaves the image for the next message.
const attachSettle = Duration(milliseconds: 700);
const attachSettleEach = Duration(milliseconds: 250);

/// Pause between the pasted text and Enter, so the agent treats Enter as a
/// submit, not as part of the paste.
const submitPause = Duration(milliseconds: 80);

/// Paste [files] (each followed by a space), wait for the agent to attach
/// them, paste [text] and, when [submit], press Enter.
///
/// Every byte goes through [send], in order. Pasting through the emulator
/// went through an async queue while Enter went straight to the shell, so
/// Enter could arrive before the text and send the image alone.
Future<void> sendComposed({
  required List<String> files,
  required String text,
  required bool bracketed,
  required Future<void> Function(String) send,
  bool submit = true,
  Future<void> Function(Duration) wait = Future<void>.delayed,
}) async {
  Future<void> paste(String s) {
    final clean = s.replaceAll('\x1b[201~', '');
    return send(bracketed ? '\x1b[200~$clean\x1b[201~' : clean);
  }

  for (final p in files) {
    await paste(p);
    await send(' ');
  }
  if (files.isNotEmpty && submit) {
    await wait(attachSettle + attachSettleEach * (files.length - 1));
  }
  if (text.isNotEmpty) {
    await paste(text);
    if (submit) await wait(submitPause);
  }
  if (submit) await send('\r');
}

final class TerminalSession {
  TerminalSession._(this.emulator, this.runner, this.modifiers);

  factory TerminalSession.create({
    required String hostId,
    required HostConnections connections,
    String? session,
    String? kind,
  }) {
    final emu = XtermEmulator();
    final mods = ValueNotifier(const ModifierState());
    final s = RemoteSession.fromJson({'name': session, 'kind': kind});
    final runner = TerminalRunner(
      hostId: hostId,
      connections: connections,
      emulator: _ModifiedInput(emu, mods),
      attachCommand: s?.attachCommand,
    );
    return TerminalSession._(emu, runner, mods);
  }

  final XtermEmulator emulator;
  final TerminalRunner runner;
  final ValueNotifier<ModifierState> modifiers;

  /// Chat composer state, kept while the session lives.
  bool chatOpen = false;

  /// The keys bar shows the arrow, symbol and preset rows.
  bool moreKeys = false;
  String draft = '';
  final attachments = <ChatAttachment>[];

  /// Pastes uploaded paths one by one, each as its own paste, so agents that
  /// accept dropped files (Claude Code shows `[Image #1]`) recognise them.
  Future<void> pastePaths(Iterable<String> paths) => sendComposed(
    files: paths.toList(),
    text: '',
    bracketed: emulator.terminal.bracketedPasteMode,
    send: runner.send,
    submit: false,
  );

  /// Sends a composed message: its attachments, then the text as one paste
  /// (bracketed when the app asks for it, so newlines do not submit early),
  /// then Enter.
  Future<void> sendMessage(String text) {
    final files = [for (final a in attachments) a.remotePath];
    attachments.clear();
    return sendComposed(
      files: files,
      text: text,
      bracketed: emulator.terminal.bracketedPasteMode,
      send: runner.send,
    );
  }

  Future<void> dispose() async {
    await runner.dispose();
    await emulator.dispose();
    modifiers.dispose();
  }
}

/// Applies sticky Ctrl/Alt from the bar to soft-keyboard input.
class _ModifiedInput extends XtermProxy {
  _ModifiedInput(super.inner, this._mods);
  final ValueNotifier<ModifierState> _mods;

  @override
  Stream<String> get input => inner.input.map((s) {
    final m = _mods.value;
    if (!m.any) return s;
    final (out, next) = m.apply(s);
    _mods.value = next;
    return out;
  });
}
