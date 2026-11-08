import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../views/inbox_view.dart';

class InboxContainer extends ConsumerWidget {
  const InboxContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(inboxProvider);
    final hosts = ref.watch(hostsProvider).value ?? const [];
    final l = context.l10n;
    String alias(String id) => hosts.where((h) => h.id == id).firstOrNull?.alias ?? l.host;
    return Scaffold(
      body: events.when(
        data: (list) => InboxView(
          events: list,
          hostAlias: alias,
          onOpen: (e) => context.push('/inbox/${e.hostId}/${e.id}'),
        ),
        loading: () => MoleMessage(title: l.navInbox, busy: true),
        error: (e, _) => FailurePanel(failure: e),
      ),
    );
  }
}
