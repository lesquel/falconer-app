import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../views/hosts_view.dart';

class HostsContainer extends ConsumerWidget {
  const HostsContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosts = ref.watch(hostsProvider);
    final events = ref.watch(inboxProvider).value ?? const [];
    return Scaffold(
      body: hosts.when(
        data: (list) => HostsView(
          hosts: list,
          events: events,
          onOpen: (h) => context.push('/hosts/${h.id}'),
          onTerminal: (h) => context.push('/terminal/${h.id}'),
          onPair: () => context.push('/pair'),
          onAdd: () => context.push('/hosts/new'),
          onOpenEvent: (e) => context.push('/inbox/${e.hostId}/${e.id}'),
          onInbox: () => context.go('/inbox'),
        ),
        loading: () => const MoleMessage(title: 'OpenMosh', busy: true),
        error: (e, _) => FailurePanel(failure: e),
      ),
    );
  }
}
