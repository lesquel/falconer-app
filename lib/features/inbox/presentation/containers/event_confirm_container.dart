import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../domain/entities/inbox_event.dart';
import '../controllers/event_confirm_controller.dart';
import '../views/event_confirm_view.dart';

class EventConfirmContainer extends ConsumerWidget {
  const EventConfirmContainer({super.key, required this.hostId, required this.eventId, this.action});
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

    return Scaffold(
      appBar: AppBar(title: const Text('Agent request')),
      body: event == null
          ? const Center(child: Text('Event not found. It may have been cleared.'))
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
            ),
    );
  }
}
