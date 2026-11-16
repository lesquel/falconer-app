import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/themed_falcon.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';

/// Shown over the app while it is locked.
class LockView extends StatelessWidget {
  const LockView({super.key, required this.onUnlock, required this.busy});

  final VoidCallback onUnlock;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    return Material(
      color: c.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ThemedFalcon(size: 150, semanticLabel: null),
                const SizedBox(height: 16),
                Text(
                  l.lockedTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.foreground),
                ),
                const SizedBox(height: 6),
                Text(
                  l.lockedBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: c.muted),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: busy ? null : onUnlock,
                  icon: const Icon(Icons.lock_open),
                  label: Text(l.unlock),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
