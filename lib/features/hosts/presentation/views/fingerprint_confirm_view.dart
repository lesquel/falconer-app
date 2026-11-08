import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
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
  Widget build(BuildContext context) {
    final l = context.l10n;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.verifyHostKeyOf(address), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(l.verifyHostKeyHelp),
        const SizedBox(height: 12),
        FingerprintCard(label: l.presentedHostKey, fingerprint: fingerprint),
        const SizedBox(height: 16),
        FilledButton(onPressed: onTrust, child: Text(l.trustAndSave)),
        TextButton(onPressed: onCancel, child: Text(l.cancel)),
      ],
    );
  }
}
