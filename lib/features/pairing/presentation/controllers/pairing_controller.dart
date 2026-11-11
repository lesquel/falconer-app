import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../../hosts/domain/entities/host.dart';
import '../../domain/entities/pair_payload.dart';

enum PairStep { scanning, review, pairing, done, failed }

final class PairingState {
  const PairingState({this.step = PairStep.scanning, this.raw, this.code, this.host, this.error});
  final PairStep step;
  final String? raw;
  final PairPayload? code;
  final Host? host;
  final String? error;
}

class PairingController extends Notifier<PairingState> {
  @override
  PairingState build() => const PairingState();

  void scanned(String raw) {
    if (state.step != PairStep.scanning) return;
    try {
      final code = ref.read(pairWithQrProvider).inspect(raw);
      state = PairingState(step: PairStep.review, raw: raw, code: code);
    } on AppFailure catch (e) {
      state = PairingState(step: PairStep.failed, error: e.message);
    }
  }

  Future<void> confirm(String deviceName) async {
    final raw = state.raw;
    if (raw == null) return;
    state = PairingState(step: PairStep.pairing, raw: raw, code: state.code);
    try {
      final name = deviceName.trim().isEmpty ? 'OpenMosh device' : deviceName.trim();
      final host = await ref.read(pairWithQrProvider)(
        raw,
        deviceName: name.length > 64 ? name.substring(0, 64) : name,
      );
      state = PairingState(step: PairStep.done, host: host);
    } on AppFailure catch (e) {
      state = PairingState(step: PairStep.failed, error: e.message);
    }
  }

  void reset() => state = const PairingState();
}

final pairingProvider = NotifierProvider.autoDispose<PairingController, PairingState>(
  PairingController.new,
);
