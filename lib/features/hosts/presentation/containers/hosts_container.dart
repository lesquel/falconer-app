import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../views/hosts_view.dart';

class HostsContainer extends ConsumerWidget {
  const HostsContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(hostsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hosts'),
        actions: [
          IconButton(
            tooltip: 'Scan pairing code',
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/pair'),
          ),
          IconButton(
            tooltip: 'Add host manually',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/hosts/new'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-host',
        icon: const Icon(Icons.add),
        label: const Text('Add host'),
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Scan pairing code'),
                  subtitle: const Text('Run `openmosh-hook pair` on the computer'),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    context.push('/pair');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Add host manually'),
                  onTap: () {
                    Navigator.of(sheet).pop();
                    context.push('/hosts/new');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: hosts.when(
        data: (list) => HostsView(
          hosts: list,
          onOpen: (h) => context.push('/hosts/${h.id}'),
          onPair: () => context.push('/pair'),
          onAdd: () => context.push('/hosts/new'),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FailurePanel(failure: e),
      ),
    );
  }
}
