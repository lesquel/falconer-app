import 'package:flutter/material.dart';

import '../../domain/failure.dart';
import '../molecules/fingerprint_card.dart';

/// Shows a failure. A host key mismatch renders a blocking warning with no
/// way to continue (SEC-4): only [onBack] is offered.
class FailurePanel extends StatelessWidget {
  const FailurePanel({super.key, required this.failure, this.onRetry, this.onBack});

  final Object failure;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final f = failure;
    final theme = Theme.of(context);
    if (f is HostKeyMismatchFailure) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(Icons.gpp_bad, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Host key changed',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'The server presented a different key than the one pinned at pairing. '
            'This can mean someone is intercepting the connection. The connection was blocked. '
            'If you reinstalled the host on purpose, delete this host and pair it again.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FingerprintCard(label: 'Pinned', fingerprint: f.expected),
          FingerprintCard(label: 'Presented', fingerprint: f.actual),
          if (onBack != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
          ],
        ],
      );
    }
    final message = f is AppFailure ? f.message : 'Something went wrong.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
