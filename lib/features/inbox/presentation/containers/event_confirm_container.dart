import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../shared/ui/atoms/time_ago.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
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

    Future<void> run(ResponseKind k, [String? text]) async {
      final ok = await ctrl.answer(k, text: text);
      if (ok && context.mounted) context.pop();
    }

    void close() => context.canPop() ? context.pop() : context.go('/inbox');

    return Scaffold(
      body: event == null
          ? MoleMessage(
              title: 'Event not found',
              message: 'It may have been cleared.',
              actions: [TextButton(onPressed: close, child: const Text('Back'))],
            )
          : EventConfirmView(
              event: event,
              hostAlias: host?.alias ?? 'host',
              busy: state.busy,
              error: state.error,
              suggested: suggested,
              onAllow: () => run(ResponseKind.allow),
              onDeny: () => run(ResponseKind.deny),
              onText: (t) => run(ResponseKind.text, t),
              onOpenTerminal: () => context.push('/terminal/$hostId'),
              onClose: close,
              when: timeAgo(event.at, DateTime.now()),
            ),
    );
  }
}
