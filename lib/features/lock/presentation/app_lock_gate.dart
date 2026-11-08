import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/ui/tokens/mosh_colors.dart';
import '../domain/app_lock.dart';
import 'views/lock_view.dart';

/// Wraps the whole app. While locked, the content stays mounted but is
/// offstage (not painted, not in semantics) and the [LockView] covers it.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.lock, required this.enabled, required this.child});

  final AppLock lock;

  /// The "Lock OpenMosh" setting; null while settings are loading.
  final bool? enabled;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _started = false;
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _maybeStart();
  }

  @override
  void didUpdateWidget(AppLockGate old) {
    super.didUpdateWidget(old);
    _maybeStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _maybeStart() {
    final enabled = widget.enabled;
    if (_started || enabled == null) return;
    _started = true;
    widget.lock.coldStart(enabled: enabled);
    if (widget.lock.locked) {
      _dropFocus();
      _promptAfterFrame();
    }
  }

  /// Offstage content keeps its focus; a hardware keyboard could still type
  /// into a hidden terminal.
  void _dropFocus() => FocusManager.instance.primaryFocus?.unfocus();

  void _promptAfterFrame() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_unlock()));

  Future<void> _unlock() async {
    if (_unlocking) return;
    setState(() => _unlocking = true);
    try {
      await widget.lock.unlock();
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        widget.lock.backgrounded();
      case AppLifecycleState.resumed:
        // The verification prompt itself can send the app to the background.
        final enabled = !_unlocking && (widget.enabled ?? false);
        final was = widget.lock.locked;
        widget.lock.resumed(enabled: enabled);
        if (!was && widget.lock.locked) {
          _dropFocus();
          setState(() {});
          _promptAfterFrame();
        }
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = widget.enabled == null;
    final hidden = loading || widget.lock.locked;
    return Stack(
      fit: StackFit.expand,
      children: [
        TickerMode(
          enabled: !hidden,
          child: Offstage(offstage: hidden, child: widget.child),
        ),
        if (loading) ColoredBox(color: MoshColors.of(context).background),
        if (!loading && widget.lock.locked) LockView(onUnlock: _unlock, busy: _unlocking),
      ],
    );
  }
}
