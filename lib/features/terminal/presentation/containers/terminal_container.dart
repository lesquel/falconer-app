import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../keyboard/domain/entities/key_presets.dart';
import '../../../keyboard/domain/entities/modifier_state.dart';
import '../../../keyboard/presentation/views/extra_keys_bar.dart';
import '../../../sessions/domain/entities/remote_session.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../data/datasources/connectivity_signals.dart';
import '../../data/datasources/xterm_emulator.dart';
import '../../domain/usecases/terminal_runner.dart';
import '../views/terminal_screen_view.dart';

class TerminalContainer extends ConsumerStatefulWidget {
  const TerminalContainer({super.key, required this.hostId, this.session, this.kind});
  final String hostId;
  final String? session;
  final String? kind;

  @override
  ConsumerState<TerminalContainer> createState() => _TerminalContainerState();
}

class _TerminalContainerState extends ConsumerState<TerminalContainer> with WidgetsBindingObserver {
  final _emu = XtermEmulator();
  late final TerminalRunner _runner;
  StreamSubscription<void>? _net;
  StreamSubscription<TerminalPhase>? _phaseSub;
  TerminalPhase _phase = TerminalPhase.idle;
  ModifierState _mods = const ModifierState();
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final s = RemoteSession.fromJson({'name': widget.session, 'kind': widget.kind});
    _runner = TerminalRunner(
      hostId: widget.hostId,
      connections: ref.read(hostConnectionsProvider),
      emulator: _ModifiedInput(_emu, () => _mods, (m) => setState(() => _mods = m)),
      attachCommand: s?.attachCommand,
    );
    _phaseSub = _runner.phases.listen((p) => setState(() => _phase = p));
    _net = networkRegained().listen((_) => _runner.wake());
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_runner.start()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runner.wake();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_net?.cancel());
    unawaited(_phaseSub?.cancel());
    unawaited(_runner.dispose());
    unawaited(_emu.dispose());
    super.dispose();
  }

  Future<void> _upload(bool images) async {
    final source = ref.read(fileSourceProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploading = true);
    try {
      final file = await source.pick(imagesOnly: images);
      if (file == null) return;
      try {
        final text = await ref.read(uploadFileProvider)(widget.hostId, file);
        await _runner.send(text);
      } finally {
        await source.discard(file);
      }
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final host = ref.watch(hostProvider(widget.hostId)).value;
    final preset = KeyPresets.forName(
      settings.keyPreset,
      herdrPrefix: settings.herdrPrefixSequence,
    );
    final failure = _phase == TerminalPhase.failed ? _runner.failure : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session ?? host?.alias ?? 'Terminal'),
        actions: [
          IconButton(
            tooltip: 'Upload image',
            icon: const Icon(Icons.image_outlined),
            onPressed: _uploading ? null : () => _upload(true),
          ),
          IconButton(
            tooltip: 'Upload file',
            icon: const Icon(Icons.attach_file),
            onPressed: _uploading ? null : () => _upload(false),
          ),
        ],
      ),
      body: TerminalScreenView(
        terminal: _emu.terminal,
        phase: _phase,
        fontSize: settings.fontSize,
        overlay: failure == null
            ? null
            : FailurePanel(
                failure: failure,
                onBack: () => context.pop(),
                onRetry: failure is HostKeyMismatchFailure
                    ? null
                    : () => _runner.wake(restart: true),
              ),
        keysBar: ExtraKeysBar(
          base: KeyPresets.base,
          preset: preset,
          modifiers: _mods,
          onKey: (seq) => _runner.send(seq),
          onModifier: (m) => setState(() => _mods = _mods.toggle(m)),
          onModifierLock: (m) => setState(() => _mods = _mods.lock(m)),
        ),
      ),
    );
  }
}

/// Applies sticky Ctrl/Alt from the bar to soft-keyboard input.
class _ModifiedInput extends XtermProxy {
  _ModifiedInput(super.inner, this._mods, this._update);
  final ModifierState Function() _mods;
  final void Function(ModifierState) _update;

  @override
  Stream<String> get input => inner.input.map((s) {
    final m = _mods();
    if (!m.any) return s;
    final (out, next) = m.apply(s);
    _update(next);
    return out;
  });
}
