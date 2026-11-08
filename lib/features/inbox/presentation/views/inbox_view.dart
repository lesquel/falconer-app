import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/status_badge.dart';
import '../../../../shared/ui/atoms/time_ago.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/inbox_event.dart';

class InboxView extends StatelessWidget {
  const InboxView({
    super.key,
    required this.events,
    required this.hostAlias,
    required this.onOpen,
    this.now,
  });

  final List<InboxEvent> events;
  final String Function(String hostId) hostAlias;
  final ValueChanged<InboxEvent> onOpen;
  final DateTime? now;

  static String responseLabel(AppLocalizations l, ResponseKind r) => switch (r) {
    ResponseKind.allow => l.responseAllow,
    ResponseKind.deny => l.responseDeny,
    ResponseKind.text => l.responseText,
  };

  static (String, BadgeTone) badge(AppLocalizations l, InboxEvent e) => switch (e.status) {
    InboxStatus.pending => (
      e.kind == EventKind.question ? l.badgeQuestion : l.badgeNeedsApproval,
      BadgeTone.attention,
    ),
    InboxStatus.responding => (l.badgeSending, BadgeTone.neutral),
    InboxStatus.failed => (l.badgeFailed, BadgeTone.danger),
    InboxStatus.resolved => (
      e.response == null ? l.badgeResolved : responseLabel(l, e.response!),
      BadgeTone.success,
    ),
    InboxStatus.info => (l.badgeDone, BadgeTone.neutral),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (events.isEmpty) {
      return MoleMessage(title: l.noAgentEventsTitle, message: l.noAgentEventsBody);
    }
    final c = MoshColors.of(context);
    final clock = now ?? DateTime.now();
    final waiting = events.where((e) => e.needsAction).length;
    return ThumbPage(
      title: Text(l.navInbox),
      subtitle: waiting == 0 ? l.nothingWaiting : l.requestsWaiting(waiting),
      children: [
        for (final e in events)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EventTile(
              event: e,
              alias: hostAlias(e.hostId),
              when: timeAgo(l, e.at, clock),
              onTap: () => onOpen(e),
              muted: c.muted,
            ),
          ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.alias,
    required this.when,
    required this.onTap,
    required this.muted,
  });

  final InboxEvent event;
  final String alias;
  final String when;
  final VoidCallback onTap;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final l = context.l10n;
    final (label, tone) = InboxView.badge(l, e);
    return MoshTile(
      radius: MoshRadii.card,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$alias · ${e.agent} · $when',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
              StatusBadge(label: label, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            e.title.isEmpty ? l.agentOnHost(e.agent, alias) : e.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
