import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../atoms/falcon_logo.dart';
import '../tokens/mosh_colors.dart';

/// [FalconLogo] colored from the current theme: the iris follows the accent.
class ThemedFalcon extends StatelessWidget {
  const ThemedFalcon({super.key, this.size = 160, this.semanticLabel = defaultLabel});

  /// Replaced by the localized logo label; pass `null` to hide it.
  static const defaultLabel = 'Falconer logo';

  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return FalconLogo(
      size: size,
      // A near-black accent would vanish into the pupil.
      iris: c.accent.computeLuminance() < 0.05 ? FalconLogo.defaultIris : c.accent,
      semanticLabel: semanticLabel == defaultLabel ? context.l10n.logoSemanticLabel : semanticLabel,
    );
  }
}

/// Falcon plus a message: used for loading and empty states.
class FalconMessage extends StatelessWidget {
  const FalconMessage({
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

  /// Shows a progress bar under the falcon (loading state).
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
            ThemedFalcon(size: size, semanticLabel: null),
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
