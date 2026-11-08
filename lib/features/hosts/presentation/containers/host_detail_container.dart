import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../controllers/host_detail_controller.dart';
import '../views/host_detail_view.dart';

class HostDetailContainer extends ConsumerWidget {
  const HostDetailContainer({super.key, required this.hostId});
  final String hostId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete host?'),
        content: const Text('Removes the host, its pinned key and its inbox from this phone. '
            'Revoke the device on the host with `openmosh-hook devices revoke`.'),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(hostProvider(hostId)).value;
    final state = ref.watch(hostDetailProvider(hostId));
    final ctrl = ref.read(hostDetailProvider(hostId).notifier);
    if (host == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: Text(host.alias),
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => context.push('/hosts/$hostId/edit')),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(context, ref)),
        ],
      ),
      body: HostDetailView(
        host: host,
        sessions: state.sessions,
        agents: state.agents,
        loading: state.loading,
        error: state.error == null
            ? null
            : SizedBox(height: 320, child: FailurePanel(failure: state.error!, onRetry: ctrl.load)),
        onLoad: ctrl.load,
        onShell: () => context.push('/terminal/$hostId'),
        onAttach: (s) => context.push(
            Uri(path: '/terminal/$hostId', queryParameters: {'session': s.name, 'kind': s.kind.name}).toString()),
        onEnablePush: () => ctrl.enablePush('Android phone'),
      ),
    );
  }
}
