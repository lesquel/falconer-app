import 'package:flutter/material.dart';

enum BadgeTone { neutral, attention, success, danger }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, this.tone = BadgeTone.neutral});
  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      BadgeTone.neutral => (s.surfaceContainerHighest, s.onSurfaceVariant),
      BadgeTone.attention => (s.tertiaryContainer, s.onTertiaryContainer),
      BadgeTone.success => (s.primaryContainer, s.onPrimaryContainer),
      BadgeTone.danger => (s.errorContainer, s.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
    );
  }
}
