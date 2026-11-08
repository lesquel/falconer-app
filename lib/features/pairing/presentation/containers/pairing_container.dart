import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
import 'package:go_router/go_router.dart';

import '../controllers/pairing_controller.dart';
import '../views/pair_review_view.dart';
import '../views/pair_scan_view.dart';

class PairingContainer extends ConsumerWidget {
  const PairingContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pairingProvider);
    final ctrl = ref.read(pairingProvider.notifier);
    ref.listen(pairingProvider, (_, next) {
      if (next.step == PairStep.done && next.host != null) context.go('/hosts/${next.host!.id}');
    });

    final body = switch (state.step) {
      PairStep.review || PairStep.pairing => PairReviewView(
        code: state.code!,
        busy: state.step == PairStep.pairing,
        onPair: ctrl.confirm,
        onCancel: ctrl.reset,
      ),
      _ => PairScanView(
        error: state.error,
        onDismissError: ctrl.reset,
        onSubmit: ctrl.scanned,
        scanner: ReaderWidget(
          codeFormat: Format.qrCode,
          showGallery: false,
          showToggleCamera: false,
          onScan: (code) {
            final text = code.text;
            if (code.isValid && text != null) ctrl.scanned(text);
          },
        ),
      ),
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Pair a host')),
      body: body,
    );
  }
}
