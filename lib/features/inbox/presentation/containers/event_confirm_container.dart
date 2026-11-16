import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/time_ago.dart';
import '../../../../shared/ui/molecules/themed_falcon.dart';
import '../../domain/entities/inbox_event.dart';
import '../controllers/event_confirm_controller.dart';
import '../views/event_confirm_view.dart';

class EventConfirmContainer extends ConsumerWidget {
  const EventConfirmContainer({
    super.key,
    required this.hostId,
    required this.eventId,
    this.action,
  });
  final String hostId;
  final String eventId;
  final String? action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (hostId: hostId, eventId: eventId);
    final events = ref.watch(inboxProvider).value ?? const [];
    final event = events.where((e) => e.hostId == hostId && e.id == eventId).firstOrNull;
    final host = ref.watch(hostProvider(hostId)).value;
    final state = ref.watch(eventConfirmProvider(key));
    final ctrl = ref.read(eventConfirmProvider(key).notifier);
    final suggested = ResponseKind.values.where((k) => k.name == action).firstOrNull;
    final l = context.l10n;

    Future<void> run(ResponseKind k, [String? text]) async {
      final ok = await ctrl.answer(k, text: text, reason: l.confirmAnswerReason);
      if (ok && context.mounted) context.pop();
    }

    void close() => context.canPop() ? context.pop() : context.go('/inbox');

    return Scaffold(
      body: event == null
          ? FalconMessage(
              title: l.eventNotFound,
              message: l.eventMayBeCleared,
              actions: [TextButton(onPressed: close, child: Text(l.back))],
            )
          : EventConfirmView(
              event: event,
              hostAlias: host?.alias ?? l.host,
              busy: state.busy,
              error: state.error == null ? null : l.failureMessage(state.error!),
              suggested: suggested,
              onAllow: () => run(ResponseKind.allow),
              onDeny: () => run(ResponseKind.deny),
              onText: (t) => run(ResponseKind.text, t),
              onOpenTerminal: () => context.push('/terminal/$hostId'),
              onClose: close,
              when: timeAgo(l, event.at, DateTime.now()),
            ),
    );
  }
}
