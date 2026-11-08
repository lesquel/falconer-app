import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../domain/entities/paired_device.dart';
import '../controllers/host_detail_controller.dart';
import '../controllers/paired_devices_controller.dart';
import '../views/host_detail_view.dart';
import '../views/paired_devices_view.dart';

class HostDetailContainer extends ConsumerWidget {
  const HostDetailContainer({super.key, required this.hostId});
  final String hostId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete host?'),
        content: const Text(
          'Removes the host, its pinned key and its inbox from this phone. '
          'To also remove this phone from the host, revoke it under Paired devices first.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(hostConnectionsProvider).disconnect(hostId);
    await ref.read(manageHostsProvider).delete(hostId);
    if (context.mounted) context.go('/');
  }

  Future<bool> _confirmRevoke(BuildContext context, String alias, PairedDevice d) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(d.isThisPhone ? 'Revoke this phone?' : 'Revoke ${d.name}?'),
          content: Text(
            d.isThisPhone
                ? 'This is the phone you are using. OpenMosh will lose access to $alias: '
                      'the host removes its SSH key and push key. Pair again to get access back.'
                : 'Removes its SSH key and push key from $alias. '
                      'It can no longer connect or get notifications.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Revoke')),
          ],
        ),
      ) ==
      true;

  Future<void> _revoke(BuildContext context, WidgetRef ref, String alias, PairedDevice d) async {
    final outcome = await ref
        .read(pairedDevicesControllerProvider(hostId).notifier)
        .revoke(d, confirm: (d) => _confirmRevoke(context, alias, d));
    if (!context.mounted) return;
    final msg = switch (outcome) {
      RevokeOutcome.revoked => '${d.name} was revoked.',
      RevokeOutcome.revokedThisPhone =>
        'This phone was revoked from $alias. Pair again or delete the host.',
      _ => null,
    };
    if (msg != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(hostProvider(hostId)).value;
    final state = ref.watch(hostDetailProvider(hostId));
    final ctrl = ref.read(hostDetailProvider(hostId).notifier);
    final devices = ref.watch(pairedDevicesControllerProvider(hostId));
    final devicesCtrl = ref.read(pairedDevicesControllerProvider(hostId).notifier);
    if (host == null) {
      return const Scaffold(body: MoleMessage(title: 'Opening host', busy: true));
    }
    return Scaffold(
      body: HostDetailView(
        host: host,
        sessions: state.sessions,
        agents: state.agents,
        loading: state.loading,
        error: state.error == null
            ? null
            : SizedBox(
                height: 320,
                child: FailurePanel(failure: state.error!, onRetry: ctrl.load),
              ),
        devices: PairedDevicesView(
          devices: devices.devices,
          loading: devices.loading,
          error: devices.error == null
              ? null
              : SizedBox(
                  height: 320,
                  child: FailurePanel(failure: devices.error!, onRetry: devicesCtrl.load),
                ),
          onLoad: devicesCtrl.load,
          onRevoke: (d) => _revoke(context, ref, host.alias, d),
        ),
        onLoad: ctrl.load,
        onShell: () => context.push('/terminal/$hostId'),
        onAttach: (s) => context.push(
          Uri(
            path: '/terminal/$hostId',
            queryParameters: {'session': s.name, 'kind': s.kind.name},
          ).toString(),
        ),
        onEnablePush: () => ctrl.enablePush('Android phone'),
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        onEdit: () => context.push('/hosts/$hostId/edit'),
        onDelete: () => _delete(context, ref),
      ),
    );
  }
}
