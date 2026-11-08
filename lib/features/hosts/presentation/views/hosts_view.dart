import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/mask.dart';
import '../../../../shared/ui/atoms/sensitive_text.dart';
import '../../../../shared/ui/atoms/status_badge.dart';
import '../../../../shared/ui/atoms/time_ago.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../inbox/domain/entities/inbox_event.dart';
import '../../domain/entities/host.dart';

/// Home: greeting and status, the newest request to answer, big tiles and
/// the paired computers, all in the thumb zone.
class HostsView extends StatelessWidget {
  const HostsView({
    super.key,
    required this.hosts,
    required this.onOpen,
    required this.onPair,
    required this.onAdd,
    this.events = const [],
    this.now,
    this.onTerminal,
    this.onOpenEvent,
    this.onInbox,
  });

  final List<Host> hosts;
  final ValueChanged<Host> onOpen;
  final VoidCallback onPair;
  final VoidCallback onAdd;

  /// Inbox events, newest first; used for the status line and the approval card.
  final List<InboxEvent> events;
  final DateTime? now;
  final ValueChanged<Host>? onTerminal;
  final ValueChanged<InboxEvent>? onOpenEvent;
  final VoidCallback? onInbox;

  String _alias(AppLocalizations l, String hostId) =>
      hosts.where((h) => h.id == hostId).firstOrNull?.alias ?? l.aHost;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (hosts.isEmpty) {
      return MoleMessage(
        title: l.noComputersTitle,
        message: l.noComputersBody,
        actions: [
          FilledButton.icon(
            onPressed: onPair,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(l.scanPairingCode),
          ),
          TextButton(onPressed: onAdd, child: Text(l.addHostManually)),
        ],
      );
    }
    final c = MoshColors.of(context);
    final clock = now ?? DateTime.now();
    final waiting = events.where((e) => e.needsAction).toList();
    final first = waiting.firstOrNull;
    final today = events.where((e) => clock.difference(e.at) < const Duration(hours: 24)).length;
    final Widget title;
    if (first == null) {
      title = Text(l.allQuiet);
    } else {
      // Split the sentence around the alias so only the alias is highlighted.
      const mark = '\uFFFC';
      final parts = l.allGoodExcept(mark, waiting.length - 1).split(mark);
      title = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: parts.first),
            TextSpan(
              text: _alias(l, first.hostId),
              style: TextStyle(color: c.accent),
            ),
            TextSpan(text: parts.skip(1).join(mark)),
          ],
        ),
      );
    }
    return ThumbPage(
      eyebrow: greetingFor(l, clock),
      title: title,
      subtitle: first == null
          ? l.computersPairedNothingWaiting(hosts.length)
          : l.agentWaitingForAnswer(first.agent),
      children: [
        Row(
          children: [
            Expanded(
              child: MoshTile(
                height: 120,
                onTap: onInbox,
                semanticLabel: l.inboxTileSemantics(today, waiting.length),
                child: _TileText(
                  top: l.today,
                  big: l.eventCount(today),
                  small: l.waitingCount(waiting.length),
                  smallColor: waiting.isEmpty ? c.muted : c.accent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MoshTile(
                height: 120,
                onTap: onPair,
                semanticLabel: l.pairTileSemantics,
                child: _TileText(
                  top: l.addTile,
                  big: l.pairWithQr,
                  small: 'openmosh-hook pair',
                  smallColor: c.muted,
                ),
              ),
            ),
          ],
        ),
        if (first != null) ...[
          const SizedBox(height: 10),
          _ApprovalCard(
            event: first,
            alias: _alias(l, first.hostId),
            when: timeAgo(l, first.at, clock),
            onTap: onOpenEvent == null ? null : () => onOpenEvent!(first),
          ),
        ],
        SectionLabel(l.yourComputers),
        for (final h in hosts)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HostCard(
              host: h,
              waiting: waiting.where((e) => e.hostId == h.id).length,
              onOpen: () => onOpen(h),
              onTerminal: onTerminal == null ? null : () => onTerminal!(h),
            ),
          ),
        Align(
          alignment: Alignment.center,
          child: TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l.addHostManually),
          ),
        ),
      ],
    );
  }
}

class _TileText extends StatelessWidget {
  const _TileText({
    required this.top,
    required this.big,
    required this.small,
    required this.smallColor,
  });

  final String top;
  final String big;
  final String small;
  final Color smallColor;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(top, style: TextStyle(fontSize: 13, color: c.muted)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              big,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.1),
            ),
            Text(
              small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: smallColor),
            ),
          ],
        ),
      ],
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.event,
    required this.alias,
    required this.when,
    required this.onTap,
  });

  final InboxEvent event;
  final String alias;
  final String when;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final what = event.summary.isNotEmpty
        ? event.summary
        : (event.title.isNotEmpty ? event.title : l.needsYou);
    return MoshTile(
      key: const Key('approval_card'),
      tone: TileTone.accent,
      radius: MoshRadii.hero,
      height: 132,
      padding: const EdgeInsets.all(20),
      onTap: onTap,
      semanticLabel: l.reviewRequestSemantics(alias, event.agent, what),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$alias · ${event.agent}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              Text(when, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  what,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.1),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: c.onAccent, shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward, color: c.accent, size: 26),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HostCard extends StatelessWidget {
  const _HostCard({
    required this.host,
    required this.waiting,
    required this.onOpen,
    required this.onTerminal,
  });

  final Host host;
  final int waiting;
  final VoidCallback onOpen;
  final VoidCallback? onTerminal;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final h = host;
    return MoshTile(
      radius: MoshRadii.hero,
      padding: const EdgeInsets.all(20),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  h.alias,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
              StatusBadge(
                label: h.pushEnabled ? l.badgePush : l.badgeNoPush,
                tone: h.pushEnabled ? BadgeTone.success : BadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 2),
          SensitiveText(
            '${h.user}@${h.address}:${h.port}',
            masked: maskEndpoint(h.user, h.address, h.port),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: c.muted),
          ),
          if (waiting > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.pending_actions, size: 18, color: c.accent),
                const SizedBox(width: 6),
                Text(
                  l.waitingForYou(waiting),
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: MoshTile(
                  tone: TileTone.inverse,
                  radius: MoshRadii.key,
                  height: 52,
                  padding: EdgeInsets.zero,
                  onTap: onTerminal,
                  child: Center(
                    child: Text(l.terminal, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MoshTile(
                  tone: TileTone.raised,
                  radius: MoshRadii.key,
                  height: 52,
                  padding: EdgeInsets.zero,
                  onTap: onOpen,
                  child: Center(
                    child: Text(l.sessions, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
