import 'package:flutter/material.dart';

import '../../../../shared/ui/molecules/themed_mole.dart';

/// Shown when the remote shell exited: start it again or leave.
class SessionEndedPanel extends StatelessWidget {
  const SessionEndedPanel({super.key, required this.onReconnect, required this.onBack});

  final VoidCallback onReconnect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => MoleMessage(
    title: 'The session ended.',
    message: 'The shell on the computer exited. Start it again or go back.',
    size: 120,
    actions: [
      FilledButton.icon(
        onPressed: onReconnect,
        icon: const Icon(Icons.refresh),
        label: const Text('Reconnect'),
      ),
      TextButton(onPressed: onBack, child: const Text('Back')),
    ],
  );
}
