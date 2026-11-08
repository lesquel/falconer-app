import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';

import '../../domain/usecases/terminal_runner.dart';

class TerminalScreenView extends StatelessWidget {
  const TerminalScreenView({
    super.key,
    required this.terminal,
    required this.phase,
    required this.fontSize,
    required this.keysBar,
    this.overlay,
    this.focusNode,
    this.composer,
  });

  final Terminal terminal;
  final TerminalPhase phase;
  final double fontSize;
  final Widget keysBar;
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
    final banner = _banner;
    return Column(
      children: [
        if (banner != null)
          Material(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: SizedBox(
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Text(banner, textAlign: TextAlign.center),
              ),
            ),
          ),
        Expanded(
          child:
              overlay ??
              TerminalView(
                terminal,
                focusNode: focusNode,
                autofocus: true,
                textStyle: TerminalStyle(fontSize: fontSize, fontFamily: 'monospace'),
                keyboardType: TextInputType.visiblePassword,
              ),
        ),
        ?composer,
        keysBar,
      ],
    );
  }
}
