import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/mono_text.dart';
import 'inbox_view.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/inbox_event.dart';

/// Review an agent request and answer it. Answers are sent only after the
/// container has verified the user (biometrics / device credential).
class EventConfirmView extends StatefulWidget {
  const EventConfirmView({
    super.key,
    required this.event,
    required this.hostAlias,
    required this.busy,
    required this.onAllow,
    required this.onDeny,
    required this.onText,
    required this.onOpenTerminal,
    this.suggested,
    this.error,
    this.onClose,
    this.when,
  });

  /// Closes the screen (top-left button); hidden when null.
  final VoidCallback? onClose;

  /// Relative time of the event, shown in the top bar ("12 s ago").
  final String? when;

  final InboxEvent event;
  final String hostAlias;
  final bool busy;
  final String? error;

  /// Action chosen from the notification; highlighted, never auto-sent.
  final ResponseKind? suggested;
  final VoidCallback onAllow;
  final VoidCallback onDeny;
  final ValueChanged<String> onText;
  final VoidCallback onOpenTerminal;

  @override
  State<EventConfirmView> createState() => _EventConfirmViewState();
}

class _EventConfirmViewState extends State<EventConfirmView> {
  final _text = TextEditingController();
  final _replyFocus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _replyFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final t = Theme.of(context).textTheme;
    final c = MoshColors.of(context);
    final l = context.l10n;
    final canAnswer = e.needsAction && !widget.busy;
    final caption = [widget.hostAlias, e.agent, ?widget.when].join(' · ');
    return ThumbPage(
      onBack: widget.onClose,
      backIcon: Icons.close,
      backTooltip: l.close,
      caption: caption,
      eyebrow: l.agentAsks(e.agent),
      title: Text(e.title.isEmpty ? l.agentNeedsYou : e.title),
      children: [
        if (e.summary.isNotEmpty)
          MoshTile(
            radius: MoshRadii.tile,
            padding: const EdgeInsets.all(16),
            child: MonoText(e.summary, size: 15),
          ),
        if (!e.needsAction)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: c.muted),
                const SizedBox(width: 6),
                Text(
                  e.status == InboxStatus.resolved ? l.alreadyAnswered : l.nothingToAnswer,
                  style: TextStyle(color: c.muted),
                ),
              ],
            ),
          ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: c.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(widget.error!, style: TextStyle(color: c.danger)),
                ),
              ],
            ),
          ),
        if (widget.suggested != null && e.needsAction)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
            child: Text(
              l.youPickedInNotification(InboxView.responseLabel(l, widget.suggested!)),
              style: t.bodySmall?.copyWith(color: c.muted),
            ),
          ),
        const SizedBox(height: 18),
        MoshTile(
          key: const Key('approve'),
          tone: canAnswer ? TileTone.accent : TileTone.raised,
          radius: 34,
          height: 120,
          padding: const EdgeInsets.all(20),
          onTap: canAnswer ? widget.onAllow : null,
          semanticLabel: l.approve,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  l.approve,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: canAnswer ? c.onAccent : c.muted,
                  ),
                ),
              ),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: canAnswer ? c.onAccent : c.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 30, color: canAnswer ? c.accent : c.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Choice(
                key: const Key('deny'),
                label: l.deny,
                icon: Icons.block,
                onTap: canAnswer ? widget.onDeny : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Choice(
                key: const Key('reply'),
                label: l.reply,
                icon: Icons.reply,
                onTap: canAnswer ? _replyFocus.requestFocus : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _text,
          focusNode: _replyFocus,
          enabled: canAnswer,
          minLines: 1,
          maxLines: 5,
          maxLength: 4096,
          decoration: InputDecoration(labelText: l.replyToAgent),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: widget.onOpenTerminal,
              icon: const Icon(Icons.terminal),
              label: Text(l.openTerminal),
            ),
            TextButton(
              onPressed: canAnswer ? () => widget.onText(_text.text) : null,
              child: Text(l.sendReply),
            ),
          ],
        ),
        if (widget.busy) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            l.asksVerificationBeforeSending,
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: c.muted),
          ),
        ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final fg = onTap == null ? c.muted : c.foreground;
    return MoshTile(
      height: 72,
      padding: EdgeInsets.zero,
      onTap: onTap,
      semanticLabel: label,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }
}
