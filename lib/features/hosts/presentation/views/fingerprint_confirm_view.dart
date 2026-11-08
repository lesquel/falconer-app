import 'package:flutter/material.dart';

import '../../../../shared/ui/molecules/fingerprint_card.dart';

/// First-contact host key confirmation (SSH pairing, TRD §6.4).
class FingerprintConfirmView extends StatelessWidget {
  const FingerprintConfirmView({
    super.key,
    required this.address,
    required this.fingerprint,
    required this.onTrust,
    required this.onCancel,
  });

  final String address;
  final String fingerprint;
  final VoidCallback onTrust;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Verify the host key of $address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'On the host run:\n  ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub\n'
            'Trust it only if the fingerprint is identical. It will be pinned, and any later change '
            'will block the connection.',
          ),
          const SizedBox(height: 12),
          FingerprintCard(label: 'Presented host key', fingerprint: fingerprint),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTrust, child: const Text('It matches — trust and save')),
          TextButton(onPressed: onCancel, child: const Text('Cancel')),
        ],
      );
}
