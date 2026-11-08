import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/l10n.dart';
import '../controllers/pairing_controller.dart';
import '../views/camera_unavailable_view.dart';
import '../views/pair_review_view.dart';
import '../views/pair_success_view.dart';
import '../views/pair_scan_view.dart';

class PairingContainer extends ConsumerWidget {
  const PairingContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pairingProvider);
    final ctrl = ref.read(pairingProvider.notifier);
    // Once paired, go straight to the new host's page.
    ref.listen(pairingProvider, (prev, next) {
      final host = next.step == PairStep.done ? next.host : null;
      if (host == null || prev?.step == PairStep.done) return;
      final l = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(host.pushEnabled ? l.pairedWith(host.alias) : l.pairedWithoutPush)),
      );
      context.go('/hosts/${host.id}');
    });
    final paired = state.step == PairStep.done ? state.host : null;
    final body = switch (state.step) {
      PairStep.done when paired != null => PairSuccessView(
        alias: paired.alias,
        pushEnabled: paired.pushEnabled,
        onOpen: () => context.go('/hosts/${paired.id}'),
      ),
      PairStep.review || PairStep.pairing => PairReviewView(
        code: state.code!,
        busy: state.step == PairStep.pairing,
        onPair: ctrl.confirm,
        onCancel: ctrl.reset,
      ),
      _ => PairScanView(
        error: state.error == null ? null : context.l10n.failureMessage(state.error!),
        onDismissError: ctrl.reset,
        onSubmit: ctrl.scanned,
        scanner: _QrScanner(onCode: ctrl.scanned),
      ),
    };
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.pairAHost)),
      body: body,
    );
  }
}

/// Camera QR reader that shows why when the camera cannot start.
class _QrScanner extends StatefulWidget {
  const _QrScanner({required this.onCode});

  final ValueChanged<String> onCode;

  @override
  State<_QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<_QrScanner> {
  Exception? _error;
  int _attempt = 0;

  /// `CameraException(CameraAccessDenied…)` and similar codes from the camera plugin.
  static bool _isPermission(Exception e) {
    final text = e.toString().toLowerCase();
    return text.contains('accessdenied') || text.contains('permission');
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return CameraUnavailableView(
        permissionDenied: _isPermission(error),
        onRetry: () => setState(() {
          _error = null;
          _attempt++;
        }),
      );
    }
    return ReaderWidget(
      key: ValueKey(_attempt),
      codeFormat: Format.qrCode,
      // The code is usually on a monitor: decode almost the whole frame (default 50%),
      // accept light-on-dark terminals and downscale high-resolution frames.
      cropPercent: 0.9,
      tryHarder: true,
      tryInverted: true,
      tryDownscale: true,
      showGallery: false,
      showToggleCamera: false,
      onControllerCreated: (_, e) {
        if (e != null && mounted) setState(() => _error = e);
      },
      onScan: (code) {
        final text = code.text;
        if (code.isValid && text != null) widget.onCode(text);
      },
    );
  }
}
