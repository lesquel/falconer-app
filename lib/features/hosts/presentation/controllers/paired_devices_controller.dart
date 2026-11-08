import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../domain/entities/paired_device.dart';

final class PairedDevicesState {
  const PairedDevicesState({this.devices, this.loading = false, this.error});
  final List<PairedDevice>? devices;
  final bool loading;
  final Object? error;
}

enum RevokeOutcome { cancelled, revoked, revokedThisPhone, failed }

class PairedDevicesController extends Notifier<PairedDevicesState> {
  PairedDevicesController(this.hostId);
  final String hostId;

  @override
  PairedDevicesState build() => const PairedDevicesState();

  Future<void> load() async {
    state = PairedDevicesState(devices: state.devices, loading: true);
    try {
      state = PairedDevicesState(devices: await ref.read(pairedDevicesProvider).list(hostId));
    } catch (e) {
      state = PairedDevicesState(devices: state.devices, error: e);
    }
  }

  /// [confirm] shows the confirmation dialog; user verification follows it.
  Future<RevokeOutcome> revoke(
    PairedDevice device, {
    required Future<bool> Function(PairedDevice) confirm,
  }) async {
    if (!await confirm(device)) return RevokeOutcome.cancelled;
    state = PairedDevicesState(devices: state.devices, loading: true);
    try {
      final self = await ref.read(pairedDevicesProvider).revoke(hostId, device);
      state = PairedDevicesState(devices: [...?state.devices?.where((d) => d.id != device.id)]);
      return self ? RevokeOutcome.revokedThisPhone : RevokeOutcome.revoked;
    } on UserCancelledFailure {
      state = PairedDevicesState(devices: state.devices);
      return RevokeOutcome.cancelled;
    } catch (e) {
      state = PairedDevicesState(devices: state.devices, error: e);
      return RevokeOutcome.failed;
    }
  }
}

final pairedDevicesControllerProvider = NotifierProvider.autoDispose
    .family<PairedDevicesController, PairedDevicesState, String>(PairedDevicesController.new);
