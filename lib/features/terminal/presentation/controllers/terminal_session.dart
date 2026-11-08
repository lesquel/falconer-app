import 'package:flutter/foundation.dart';

import '../../../hosts/domain/usecases/host_connections.dart';
import '../../../keyboard/domain/entities/modifier_state.dart';
import '../../../sessions/domain/entities/remote_session.dart';
import '../../data/datasources/xterm_emulator.dart';
import '../../domain/usecases/terminal_runner.dart';

/// One terminal: emulator, connection runner and sticky modifier state.
/// Lives in the session pool so it can outlive its screen.
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
