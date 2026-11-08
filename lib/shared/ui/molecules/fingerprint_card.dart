import 'package:flutter/material.dart';

import '../atoms/mono_text.dart';

class FingerprintCard extends StatelessWidget {
  const FingerprintCard({super.key, required this.label, required this.fingerprint});
  final String label;
  final String fingerprint;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              MonoText(fingerprint, size: 14),
            ],
          ),
        ),
      );
}
