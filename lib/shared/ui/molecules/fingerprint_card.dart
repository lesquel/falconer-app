import 'package:flutter/material.dart';

import '../../domain/mask.dart';
import '../atoms/sensitive_text.dart';

/// A host key fingerprint, masked until the eye reveals it. [revealLabel]
/// names the reveal action where the user must compare (`Show to compare`).
class FingerprintCard extends StatelessWidget {
  const FingerprintCard({
    super.key,
    required this.label,
    required this.fingerprint,
    this.revealLabel,
  });
  final String label;
  final String fingerprint;
  final String? revealLabel;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          SensitiveText(
            fingerprint,
            masked: maskFingerprint(fingerprint),
            revealLabel: revealLabel,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
