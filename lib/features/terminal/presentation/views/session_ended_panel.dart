import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';

/// Shown when the remote shell exited: start it again or leave.
class SessionEndedPanel extends StatelessWidget {
  const SessionEndedPanel({super.key, required this.onReconnect, required this.onBack});

  final VoidCallback onReconnect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return MoleMessage(
      title: l.sessionEndedTitle,
      message: l.sessionEndedBody,
      size: 120,
      actions: [
        FilledButton.icon(
          onPressed: onReconnect,
          icon: const Icon(Icons.refresh),
          label: Text(l.reconnect),
        ),
        TextButton(onPressed: onBack, child: Text(l.back)),
      ],
    );
  }
}
