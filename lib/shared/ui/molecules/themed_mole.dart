import 'package:flutter/material.dart';

import '../atoms/mole_logo.dart';
import '../tokens/mosh_colors.dart';

/// [MoleLogo] colored from the current theme: goggles follow the accent.
class ThemedMole extends StatelessWidget {
  const ThemedMole({super.key, this.size = 160, this.semanticLabel = 'OpenMosh mole'});

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return MoleLogo(
      size: size,
      // A black accent would vanish into the goggle frames.
      goggles: c.accent.computeLuminance() < 0.05 ? const Color(0xFF6B93FF) : c.accent,
      ground: c.surfaceHigh,
      bubble: c.isDark ? c.inverse : c.surfaceHigh,
      bubbleInk: c.isDark ? const Color(0xFF1F4FD8) : c.accent,
      semanticLabel: semanticLabel,
    );
  }
}

/// Mole plus a message: used for loading and empty states.
class MoleMessage extends StatelessWidget {
  const MoleMessage({
    super.key,
    required this.title,
    this.message,
    this.actions = const [],
    this.size = 150,
    this.busy = false,
  });

  final String title;
  final String? message;
  final List<Widget> actions;
  final double size;

  /// Shows a progress bar under the mole (loading state).
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final t = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ThemedMole(size: size, semanticLabel: null),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: c.foreground),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: t.bodyMedium?.copyWith(color: c.muted),
              ),
            ],
            if (busy) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  color: c.accent,
                  backgroundColor: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 20),
              ...actions.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(width: double.infinity, child: a),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
