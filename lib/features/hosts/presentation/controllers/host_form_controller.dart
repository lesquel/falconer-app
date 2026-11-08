import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../domain/entities/host.dart';
import '../../domain/entities/host_draft.dart';

/// Manual add: form -> probe host key -> explicit confirmation -> save.
final class HostFormState {
  const HostFormState({this.draft, this.keyId, this.probed, this.busy = false, this.error, this.saved});
  final HostDraft? draft;
  final String? keyId;
  final String? probed;
  final bool busy;
  final String? error;
  final Host? saved;
}

class HostFormController extends Notifier<HostFormState> {
  @override
  HostFormState build() => const HostFormState();

  Future<void> probe(HostDraft draft, String? keyId) async {
    state = HostFormState(draft: draft, keyId: keyId, busy: true);
    try {
      final fp = await ref.read(manageHostsProvider).probe(draft);
      state = HostFormState(draft: draft, keyId: keyId, probed: fp);
    } on AppFailure catch (e) {
      state = HostFormState(draft: draft, keyId: keyId, error: e.message);
    }
  }

  Future<void> trust() async {
    final s = state;
    if (s.draft == null || s.probed == null) return;
    final host = await ref.read(manageHostsProvider).addConfirmed(s.draft!, confirmedFingerprint: s.probed!, keyId: s.keyId);
    state = HostFormState(saved: host);
  }

  void cancel() => state = HostFormState(draft: state.draft, keyId: state.keyId);

  Future<Host?> edit(Host host, HostDraft draft, String? keyId) async {
    try {
      return await ref.read(manageHostsProvider).edit(host, draft, keyId: keyId);
    } on AppFailure catch (e) {
      state = HostFormState(draft: draft, keyId: keyId, error: e.message);
      return null;
    }
  }
}

final hostFormProvider = NotifierProvider.autoDispose<HostFormController, HostFormState>(HostFormController.new);
