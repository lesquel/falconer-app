import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

/// Shown in place of the camera preview when the camera cannot start.
class CameraUnavailableView extends StatelessWidget {
  const CameraUnavailableView({super.key, required this.permissionDenied, required this.onRetry});

  final bool permissionDenied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final message = permissionDenied ? l.cameraPermissionDenied : l.cameraUnavailable;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.no_photography_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: Text(l.retry)),
          ],
        ),
      ),
    );
  }
}
