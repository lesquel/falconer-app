import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

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

  String? get _banner => switch (phase) {
    TerminalPhase.connecting => 'Connecting…',
    TerminalPhase.reconnecting => 'Reconnecting…',
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final banner = _banner;
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
                      child: TerminalView(
                        terminal,
                        focusNode: focusNode,
                        autofocus: true,
                        theme: theme,
                        textStyle: TerminalStyle(fontSize: fontSize, fontFamily: 'monospace'),
                        keyboardType: TextInputType.visiblePassword,
                      ),
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
