import 'package:flutter/material.dart';

/// Shown when the remote shell exited: start it again or leave.
class SessionEndedPanel extends StatelessWidget {
  const SessionEndedPanel({super.key, required this.onReconnect, required this.onBack});

  final VoidCallback onReconnect;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('The session ended.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onReconnect,
            icon: const Icon(Icons.refresh),
            label: const Text('Reconnect'),
          ),
          TextButton(onPressed: onBack, child: const Text('Back')),
        ],
      ),
    ),
  );
}
