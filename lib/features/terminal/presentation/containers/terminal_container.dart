import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../keyboard/domain/entities/key_presets.dart';
import '../../../keyboard/presentation/views/extra_keys_bar.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../data/datasources/connectivity_signals.dart';
import '../../domain/usecases/terminal_runner.dart';
import '../controllers/chat_attachment.dart';
import '../controllers/terminal_session.dart';
import '../controllers/terminal_session_pool.dart';
import '../views/chat_composer.dart';
import '../views/session_ended_panel.dart';
import '../views/terminal_palette.dart';
import '../views/terminal_screen_view.dart';

class TerminalContainer extends ConsumerStatefulWidget {
  const TerminalContainer({super.key, required this.hostId, this.session, this.kind});
  final String hostId;
  final String? session;
  final String? kind;

  @override
  ConsumerState<TerminalContainer> createState() => _TerminalContainerState();
}

/// Thumbnails are read from the picked copy; skip huge originals.
const _maxPreviewBytes = 12 * 1024 * 1024;

class _TerminalContainerState extends ConsumerState<TerminalContainer> with WidgetsBindingObserver {
  late final String _key;
  late final TerminalSession _session;
  late final TerminalSessionPool<TerminalSession> _pool;
  final _focus = FocusNode();
  StreamSubscription<void>? _net;
  StreamSubscription<TerminalPhase>? _phaseSub;
  late TerminalPhase _phase;
  bool _uploading = false;

  TerminalRunner get _runner => _session.runner;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _key = terminalSessionKey(widget.hostId, widget.kind, widget.session);
    _pool = ref.read(terminalSessionPoolProvider);
    final fresh = !_pool.contains(_key);
    _session = _pool.obtain(
      _key,
      () => TerminalSession.create(
        hostId: widget.hostId,
        connections: ref.read(hostConnectionsProvider),
        session: widget.session,
        kind: widget.kind,
      ),
    );
    _phase = _runner.phase;
    _session.modifiers.addListener(_onMods);
    _phaseSub = _runner.phases.listen((p) => setState(() => _phase = p));
    _net = networkRegained().listen((_) => _runner.wake());
    if (fresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_runner.start()));
    } else {
      _runner.wake();
    }
  }

  void _onMods() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _runner.wake();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_net?.cancel());
    unawaited(_phaseSub?.cancel());
    _session.modifiers.removeListener(_onMods);
    _focus.dispose();
    final keep = ref.read(settingsProvider).value?.keepConnected ?? true;
    if (!keep) unawaited(_pool.release(_key));
    super.dispose();
  }

  void _toggleKeyboard() {
    if (_focus.hasFocus) {
      _focus.unfocus();
    } else {
      _focus.requestFocus();
      unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
    }
  }

  void _zoom(AppSettings s, double delta) => unawaited(
    ref.read(settingsRepositoryProvider).save(s.copyWith(fontSize: s.fontSize + delta)),
  );

  Future<void> _disconnect() async {
    await _pool.release(_key);
    if (mounted) _leave();
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/hosts/${widget.hostId}');

  /// Uploads picked files; returns them with a thumbnail for images.
  Future<List<ChatAttachment>> _uploadFiles(bool images) async {
    final source = ref.read(fileSourceProvider);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _uploading = true);
    try {
      final files = images ? await source.pickImages() : [?(await source.pick(imagesOnly: false))];
      final done = <ChatAttachment>[];
      try {
        for (final file in files) {
          final remote = await ref.read(uploadFileProvider)(widget.hostId, file);
          final preview = images && file.size <= _maxPreviewBytes
              ? await File(file.path).readAsBytes()
              : null;
          done.add(ChatAttachment(remotePath: remote, name: file.name, preview: preview));
        }
      } finally {
        for (final file in files) {
          await source.discard(file);
        }
      }
      return done;
    } on AppFailure catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return const [];
    } on FileSystemException {
      return const [];
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _upload(bool images) async {
    final files = await _uploadFiles(images);
    await _session.pastePaths(files.map((f) => f.remotePath));
  }

  Future<void> _attachToChat() async {
    final images = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photos'),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('File'),
              onTap: () => Navigator.of(sheet).pop(false),
            ),
          ],
        ),
      ),
    );
    if (images == null) return;
    final files = await _uploadFiles(images);
    if (mounted) setState(() => _session.attachments.addAll(files));
  }

  void _toggleChat() {
    setState(() => _session.chatOpen = !_session.chatOpen);
    if (_session.chatOpen) _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final host = ref.watch(hostProvider(widget.hostId)).value;
    final preset = KeyPresets.forName(
      settings.keyPreset,
      herdrPrefix: settings.herdrPrefixSequence,
    );
    final mods = _session.modifiers.value;
    final failure = _phase == TerminalPhase.failed ? _runner.failure : null;
    final Widget? overlay = failure != null
        ? FailurePanel(
            failure: failure,
            onBack: _leave,
            onRetry: failure is HostKeyMismatchFailure ? null : () => _runner.wake(restart: true),
          )
        : _phase == TerminalPhase.closed
        ? SessionEndedPanel(onReconnect: () => _runner.wake(restart: true), onBack: _leave)
        : null;
    final c = MoshColors.of(context);
    final subtitle = widget.session == null
        ? (host == null ? 'shell' : '${host.alias} · shell')
        : '${host?.alias ?? 'host'} · ${widget.kind ?? 'session'}';
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(68),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                CircleIconButton(icon: Icons.chevron_left, tooltip: 'Back', onPressed: _leave),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.session ?? host?.alias ?? 'Terminal',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.muted),
                      ),
                    ],
                  ),
                ),
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
                IconButton(
                  tooltip: 'Disconnect',
                  icon: const Icon(Icons.link_off),
                  onPressed: _disconnect,
                ),
              ],
            ),
          ),
        ),
      ),
      body: TerminalScreenView(
        terminal: _session.emulator.terminal,
        focusNode: _focus,
        phase: _phase,
        fontSize: settings.fontSize,
        theme: terminalThemeFor(settings.terminalScheme),
        overlay: overlay,
        composer: _session.chatOpen
            ? ChatComposer(
                initialText: _session.draft,
                attachments: List.unmodifiable(_session.attachments),
                busy: _uploading,
                onChanged: (t) => _session.draft = t,
                onSend: (t) {
                  unawaited(_session.sendMessage(t));
                  setState(() {});
                },
                onAttach: () => unawaited(_attachToChat()),
                onRemoveAttachment: (i) => setState(() => _session.attachments.removeAt(i)),
                onClose: _toggleChat,
              )
            : null,
        keysBar: ExtraKeysBar(
          base: KeyPresets.base,
          preset: preset,
          modifiers: mods,
          onKey: (seq) => _runner.send(seq),
          onModifier: (m) => _session.modifiers.value = mods.toggle(m),
          onModifierLock: (m) => _session.modifiers.value = mods.lock(m),
          expanded: _session.moreKeys,
          onToggleExpanded: () => setState(() => _session.moreKeys = !_session.moreKeys),
          pinned: [
            KeyGridButton(
              tooltip: _session.chatOpen ? 'Type in the terminal' : 'Chat',
              selected: _session.chatOpen,
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              onPressed: _toggleChat,
            ),
            KeyGridButton(tooltip: 'Keyboard', icon: Icons.keyboard, onPressed: _toggleKeyboard),
          ],
          trailing: [
            IconButton(
              tooltip: 'Smaller text',
              icon: const Icon(Icons.text_decrease),
              onPressed: settings.fontSize <= 8 ? null : () => _zoom(settings, -1),
            ),
            IconButton(
              tooltip: 'Larger text',
              icon: const Icon(Icons.text_increase),
              onPressed: settings.fontSize >= 32 ? null : () => _zoom(settings, 1),
            ),
          ],
        ),
      ),
    );
  }
}
