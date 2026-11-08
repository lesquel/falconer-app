import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/usecases/terminal_runner.dart';

class TerminalScreenView extends StatelessWidget {
  const TerminalScreenView({
    super.key,
    required this.terminal,
    required this.phase,
    required this.fontSize,
    required this.keysBar,
    this.theme = TerminalThemes.whiteOnBlack,
    this.overlay,
    this.focusNode,
    this.composer,
    this.terminalKey,
    this.controller,
    this.onPinchStart,
    this.onPinchUpdate,
    this.onPinchEnd,
    this.onTwoFingerDoubleTap,
    this.selectionBar,
    this.corner,
  });

  final Terminal terminal;
  final TerminalPhase phase;
  final double fontSize;
  final Widget keysBar;
  final TerminalTheme theme;
  final Widget? overlay;
  final FocusNode? focusNode;

  /// Chat composer shown above the keys bar, when open.
  final Widget? composer;

  final GlobalKey<TerminalViewState>? terminalKey;
  final TerminalController? controller;

  /// Two-finger pinch on the terminal: start, scale since start, end.
  final VoidCallback? onPinchStart;
  final ValueChanged<double>? onPinchUpdate;
  final VoidCallback? onPinchEnd;

  /// Two quick taps with two fingers (opens the keyboard).
  final VoidCallback? onTwoFingerDoubleTap;

  /// Actions for selected text (copy), shown over the terminal.
  final Widget? selectionBar;

  /// A control pinned to the terminal's top-right corner (exit full screen).
  final Widget? corner;

  String? _banner(AppLocalizations l) => switch (phase) {
    TerminalPhase.connecting => l.connecting,
    TerminalPhase.reconnecting => l.reconnecting,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final banner = _banner(context.l10n);
    return Column(
      children: [
        if (banner != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            child: Semantics(
              liveRegion: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(MoshRadii.key),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.sync, size: 16, color: c.foreground),
                    const SizedBox(width: 8),
                    Text(
                      banner,
                      style: TextStyle(color: c.foreground, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MoshRadii.card),
              child: ColoredBox(
                color: overlay == null ? theme.background : c.surface,
                child:
                    overlay ??
                    Stack(
                      children: [
                        Positioned.fill(
                          child: _Pinch(
                            onStart: onPinchStart,
                            onUpdate: onPinchUpdate,
                            onEnd: onPinchEnd,
                            onTwoFingerDoubleTap: onTwoFingerDoubleTap,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                              child: TerminalView(
                                terminal,
                                key: terminalKey,
                                controller: controller,
                                focusNode: focusNode,
                                // The keyboard opens only from the keyboard button.
                                showKeyboardOnTap: false,
                                theme: theme,
                                textStyle: TerminalStyle(
                                  fontSize: fontSize,
                                  fontFamily: 'monospace',
                                ),
                                keyboardType: TextInputType.visiblePassword,
                              ),
                            ),
                          ),
                        ),
                        if (selectionBar != null)
                          Positioned(left: 8, right: 8, top: 8, child: selectionBar!),
                        if (corner != null) Positioned(right: 6, top: 6, child: corner!),
                      ],
                    ),
              ),
            ),
          ),
        ),
        ?composer,
        keysBar,
      ],
    );
  }
}

/// Reports two-finger pinches without joining the gesture arena, so the
/// terminal keeps its own taps, scrolls and selection.
class _Pinch extends StatefulWidget {
  const _Pinch({
    required this.child,
    this.onStart,
    this.onUpdate,
    this.onEnd,
    this.onTwoFingerDoubleTap,
  });
  final Widget child;
  final VoidCallback? onStart;
  final ValueChanged<double>? onUpdate;
  final VoidCallback? onEnd;
  final VoidCallback? onTwoFingerDoubleTap;

  @override
  State<_Pinch> createState() => _PinchState();
}

class _PinchState extends State<_Pinch> {
  final _points = <int, Offset>{};
  double? _startDistance;

  // Two-finger tap tracking: when the second finger landed, how far the
  // fingers moved, and when the previous two-finger tap ended.
  DateTime? _twoDownAt;
  double _moved = 0;
  DateTime? _lastTwoTap;
  static const _tapTime = Duration(milliseconds: 300);
  static const _doubleGap = Duration(milliseconds: 400);
  static const _slop = 20.0;

  double get _distance {
    final p = _points.values.take(2).toList();
    return (p[0] - p[1]).distance;
  }

  void _down(PointerDownEvent e) {
    _points[e.pointer] = e.localPosition;
    if (_points.length == 2) {
      _startDistance = _distance;
      _twoDownAt = DateTime.now();
      _moved = 0;
      widget.onStart?.call();
    } else if (_points.length > 2) {
      _twoDownAt = null;
    }
  }

  void _move(PointerMoveEvent e) {
    final before = _points[e.pointer];
    if (before == null) return;
    _moved += (e.localPosition - before).distance;
    _points[e.pointer] = e.localPosition;
    final start = _startDistance;
    if (start != null && start > 0 && _points.length >= 2) {
      widget.onUpdate?.call(_distance / start);
    }
  }

  void _up(PointerEvent e) {
    final wasTwo = _points.length == 2 && _points.containsKey(e.pointer);
    _points.remove(e.pointer);
    final downAt = _twoDownAt;
    if (wasTwo && downAt != null) {
      _twoDownAt = null;
      final now = DateTime.now();
      final quick = now.difference(downAt) <= _tapTime && _moved <= _slop;
      if (quick && e is PointerUpEvent) {
        final last = _lastTwoTap;
        if (last != null && now.difference(last) <= _doubleGap) {
          _lastTwoTap = null;
          widget.onTwoFingerDoubleTap?.call();
        } else {
          _lastTwoTap = now;
        }
      }
    }
    if (_startDistance != null && _points.length < 2) {
      _startDistance = null;
      widget.onEnd?.call();
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerMove: _move,
    onPointerUp: _up,
    onPointerCancel: _up,
    child: widget.child,
  );
}
