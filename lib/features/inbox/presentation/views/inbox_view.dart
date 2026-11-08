import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/status_badge.dart';
import '../../domain/entities/inbox_event.dart';

class InboxView extends StatelessWidget {
  const InboxView({super.key, required this.events, required this.hostAlias, required this.onOpen});

  final List<InboxEvent> events;
  final String Function(String hostId) hostAlias;
  final ValueChanged<InboxEvent> onOpen;

  static (String, BadgeTone) badge(InboxEvent e) => switch (e.status) {
        InboxStatus.pending => (e.kind == EventKind.question ? 'question' : 'needs approval', BadgeTone.attention),
        InboxStatus.responding => ('sending…', BadgeTone.neutral),
        InboxStatus.failed => ('failed', BadgeTone.danger),
        InboxStatus.resolved => (e.response?.name ?? 'resolved', BadgeTone.success),
        InboxStatus.info => ('done', BadgeTone.neutral),
      };

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Center(child: Text('No agent events yet.'));
    }
    return ListView.separated(
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final e = events[i];
        final (label, tone) = badge(e);
        return ListTile(
          title: Text(e.title.isEmpty ? '${e.agent} on ${hostAlias(e.hostId)}' : e.title,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text('${hostAlias(e.hostId)} · ${e.agent}', maxLines: 1),
          trailing: StatusBadge(label: label, tone: tone),
          onTap: () => onOpen(e),
        );
      },
    );
  }
}
