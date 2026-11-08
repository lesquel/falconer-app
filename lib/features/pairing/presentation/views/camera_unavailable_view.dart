import 'package:flutter/material.dart';

/// Shown in place of the camera preview when the camera cannot start.
class CameraUnavailableView extends StatelessWidget {
  const CameraUnavailableView({super.key, required this.permissionDenied, required this.onRetry});

  final bool permissionDenied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final message = permissionDenied
        ? 'OpenMosh cannot use the camera. Allow it in Android Settings > Apps > OpenMosh > '
              'Permissions > Camera, then tap Retry.'
        : 'The camera could not start. Close other apps using it and tap Retry.';
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
