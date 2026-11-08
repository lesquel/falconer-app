import 'package:flutter/material.dart';

import '../tokens/mosh_colors.dart';

enum BadgeTone { neutral, attention, success, danger }

/// Small pill with a text label: the label always names the state, so the
/// color is never the only signal.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.neutral});
  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final (bg, fg) = switch (tone) {
      BadgeTone.neutral => (c.surfaceHigh, c.muted),
      BadgeTone.attention => (c.accent, c.onAccent),
      BadgeTone.success => (c.inverse, c.onInverse),
      BadgeTone.danger => (c.surfaceHigh, c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}
