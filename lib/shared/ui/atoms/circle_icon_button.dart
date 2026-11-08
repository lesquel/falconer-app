import 'package:flutter/material.dart';

import '../tokens/mosh_colors.dart';

/// 48 px round icon button on a card-colored disc (back, close, small actions).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: c.surface,
        foregroundColor: c.foreground,
        disabledForegroundColor: c.muted,
        minimumSize: const Size(48, 48),
        fixedSize: const Size(48, 48),
      ),
    );
  }
}
