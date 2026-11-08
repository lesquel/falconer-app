import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:xterm/xterm.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
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
import '../views/shortcut_dialog.dart';
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
  final _termKey = GlobalKey<TerminalViewState>();
  final _selection = TerminalController();

  /// Font size while a pinch is in progress; saved when the fingers lift.
  double? _pinchFont;
  double _pinchBase = 14;
  bool _fullScreen = false;
  StreamSubscription<void>? _net;
  StreamSubscription<TerminalPhase>? _phaseSub;
  late TerminalPhase _phase;
  bool _uploading = false;

  /// False until the user is verified when the shell is already live (a
  /// pooled session or a reused connection): nothing of it is shown before.
  bool _verified = true;

  /// Last seen "Keep sessions connected"; `ref` is unusable in [dispose].
  bool _keepConnected = true;

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
    _selection.addListener(_onMods);
    _phaseSub = _runner.phases.listen((p) => setState(() => _phase = p));
    _net = networkRegained().listen((_) => _runner.wake());
    final reused = !fresh || ref.read(hostConnectionsProvider).isConnected(widget.hostId);
    if (reused) {
      _verified = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_verifyThenShow(fresh)));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_runner.start()));
    }
  }

  /// A live shell opens without the key prompt, so it needs its own check
  /// unless the user was verified in the last few minutes. A refusal leaves.
  Future<void> _verifyThenShow(bool fresh) async {
    final reason = context.l10n.verifyToShowTerminal;
    final ok = await ref.read(userPresenceProvider).ensureRecent(reason);
    if (!mounted) return;
    if (!ok) {
      _leave();
      return;
    }
    setState(() => _verified = true);
    if (fresh) {
      unawaited(_runner.start());
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
    _selection.removeListener(_onMods);
    _selection.dispose();
    _focus.dispose();
    if (_fullScreen) {
      unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
    }
    if (!_keepConnected) unawaited(_pool.release(_key));
    super.dispose();
  }

  bool get _keyboardOpen => _focus.hasFocus && MediaQuery.viewInsetsOf(context).bottom > 0;

  void _toggleKeyboard() {
    final view = _termKey.currentState;
    if (_keyboardOpen) {
      view?.closeKeyboard();
      _focus.unfocus();
      return;
    }
    if (_session.chatOpen) setState(() => _session.chatOpen = false);
    // Opens the input connection directly: focusing first and asking the
    // platform to show the keyboard later raced and needed a second tap.
    view?.requestKeyboard();
  }

  void _pinchStart(AppSettings s) => _pinchBase = s.fontSize;

  void _pinchUpdate(double scale) =>
      setState(() => _pinchFont = (_pinchBase * scale).clamp(8, 32).toDouble());

  void _pinchEnd(AppSettings s) {
    final f = _pinchFont;
    if (f == null) return;
    final rounded = (f * 2).round() / 2;
    unawaited(
      ref
          .read(settingsRepositoryProvider)
          .save(s.copyWith(fontSize: rounded))
          .whenComplete(() => mounted ? setState(() => _pinchFont = null) : null),
    );
  }

  void _toggleFullScreen() {
    setState(() => _fullScreen = !_fullScreen);
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        _fullScreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      ),
    );
  }

  Future<void> _copySelection() async {
    final range = _selection.selection;
    if (range == null) return;
    final text = _session.emulator.terminal.buffer.getText(range).trimRight();
    _selection.clearSelection();
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.copied)));
    }
  }

  Future<void> _addShortcut(AppSettings s) async {
    final key = await showShortcutDialog(context);
    if (key == null) return;
    await ref.read(settingsRepositoryProvider).save(s.copyWith(customKeys: [...s.customKeys, key]));
  }

  Future<void> _removeShortcut(AppSettings s, int i) async {
    final label = s.customKeys[i].label;
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(l.removeShortcutTitle(label)),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.of(d).pop(true), child: Text(l.remove)),
        ],
      ),
    );
    if (ok != true) return;
    final keys = [...s.customKeys]..removeAt(i);
    await ref.read(settingsRepositoryProvider).save(s.copyWith(customKeys: keys));
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
    final l = context.l10n;
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
      messenger.showSnackBar(SnackBar(content: Text(l.failureMessage(e.message))));
      return const [];
    } on FileSystemException {
      return const [];
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _attachToChat() async {
    final l = context.l10n;
    final images = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l.attachPhotos),
              onTap: () => Navigator.of(sheet).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: Text(l.attachFile),
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
    _keepConnected = ref.watch(settingsProvider).value?.keepConnected ?? true;
    if (!_verified) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final host = ref.watch(hostProvider(widget.hostId)).value;
    final preset = KeyPresets.forName(
      KeyPresets.forSession(widget.kind, settings.keyPreset),
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
    final l = context.l10n;
    final subtitle = widget.session == null
        ? (host == null ? l.terminalShell : l.terminalHostShell(host.alias))
        : l.terminalHostSession(
            host?.alias ?? l.terminalHostFallback,
            widget.kind ?? l.terminalSessionFallback,
          );
    return Scaffold(
      appBar: _fullScreen
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(68),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.chevron_left,
                        tooltip: l.back,
                        onPressed: _leave,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.session ?? host?.alias ?? l.terminalTitle,
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
                      if (widget.session == null)
                        IconButton(
                          key: const Key('switch_to_herdr'),
                          tooltip: l.openHerdrHint,
                          icon: const Icon(Icons.dashboard_outlined),
                          // From a plain shell, re-open as the mirrored Herdr session.
                          onPressed: () => context.pushReplacement(
                            Uri(
                              path: '/terminal/${widget.hostId}',
                              queryParameters: {'session': 'default', 'kind': 'herdr'},
                            ).toString(),
                          ),
                        ),
                      IconButton(
                        tooltip: l.fullScreen,
                        icon: const Icon(Icons.fullscreen),
                        onPressed: _toggleFullScreen,
                      ),
                      IconButton(
                        tooltip: l.disconnect,
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
        fontSize: _pinchFont ?? settings.fontSize,
        terminalKey: _termKey,
        controller: _selection,
        onPinchStart: () => _pinchStart(settings),
        onPinchUpdate: _pinchUpdate,
        onPinchEnd: () => _pinchEnd(settings),
        onTwoFingerDoubleTap: () {
          if (!_keyboardOpen) _toggleKeyboard();
        },
        selectionBar: _selection.selection == null
            ? null
            : _SelectionBar(onCopy: _copySelection, onClear: _selection.clearSelection),
        corner: _fullScreen
            ? IconButton.filledTonal(
                tooltip: l.exitFullScreen,
                icon: const Icon(Icons.fullscreen_exit),
                onPressed: _toggleFullScreen,
              )
            : null,
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
          shortcuts: settings.customKeys,
          onShortcutLongPress: (i) => unawaited(_removeShortcut(settings, i)),
          shortcutExtras: [
            IconButton(
              tooltip: l.addShortcut,
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(_addShortcut(settings)),
            ),
          ],
          pinned: [
            KeyGridButton(
              tooltip: _session.chatOpen ? l.typeInTerminal : l.terminalChat,
              selected: _session.chatOpen,
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              onPressed: _toggleChat,
            ),
            KeyGridButton(tooltip: l.keyboard, icon: Icons.keyboard, onPressed: _toggleKeyboard),
          ],
          trailing: [
            IconButton(
              tooltip: l.smallerText,
              icon: const Icon(Icons.text_decrease),
              onPressed: settings.fontSize <= 8 ? null : () => _zoom(settings, -1),
            ),
            IconButton(
              tooltip: l.largerText,
              icon: const Icon(Icons.text_increase),
              onPressed: settings.fontSize >= 32 ? null : () => _zoom(settings, 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.onCopy, required this.onClear});
  final VoidCallback onCopy;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        color: c.inverse,
        borderRadius: BorderRadius.circular(MoshRadii.key),
        elevation: 2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: c.onInverse),
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l.copy),
              onPressed: onCopy,
            ),
            IconButton(
              tooltip: l.clearSelection,
              color: c.onInverse,
              icon: const Icon(Icons.close, size: 18),
              onPressed: onClear,
            ),
          ],
        ),
      ),
    );
  }
}
