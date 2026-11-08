import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/entities/host_draft.dart';
import '../controllers/host_form_controller.dart';
import '../views/fingerprint_confirm_view.dart';
import '../views/host_form_view.dart';

class HostFormContainer extends ConsumerWidget {
  const HostFormContainer({super.key, this.hostId});
  final String? hostId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hostFormProvider);
    final ctrl = ref.read(hostFormProvider.notifier);
    final keys = ref.watch(keysProvider).value ?? const [];
    ref.listen(hostFormProvider, (_, next) {
      if (next.saved != null) context.go('/hosts/${next.saved!.id}');
    });

    if (hostId != null) {
      final host = ref.watch(hostProvider(hostId!)).value;
      if (host == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.editHost)),
        body: HostFormView(
          keys: keys,
          lockAddress: true,
          initial: HostDraft(
            alias: host.alias,
            address: host.address,
            port: host.port,
            user: host.user,
          ),
          initialKeyId: host.keyId,
          error: state.error,
          onSubmit: (d, k) async {
            final saved = await ctrl.edit(host, d, k);
            if (saved != null && context.mounted) context.pop();
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.addHost)),
      body: state.probed != null
          ? FingerprintConfirmView(
              address: state.draft!.address,
              fingerprint: state.probed!,
              onTrust: ctrl.trust,
              onCancel: ctrl.cancel,
            )
          : HostFormView(
              keys: keys,
              initial: state.draft,
              initialKeyId: state.keyId,
              busy: state.busy,
              error: state.error,
              onSubmit: ctrl.probe,
            ),
    );
  }
}
