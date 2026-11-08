import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/mono_text.dart';
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
  });

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

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final t = Theme.of(context).textTheme;
    final canAnswer = e.needsAction && !widget.busy;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${widget.hostAlias} · ${e.agent}', style: t.labelLarge),
        const SizedBox(height: 8),
        Text(e.title.isEmpty ? 'Agent needs you' : e.title, style: t.titleLarge),
        const SizedBox(height: 12),
        if (e.summary.isNotEmpty)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: MonoText(e.summary))),
        if (!e.needsAction)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(e.status == InboxStatus.resolved ? 'Already answered.' : 'Nothing to answer.'),
          ),
        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(widget.error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        if (widget.suggested != null && e.needsAction)
          Text('You picked "${widget.suggested!.name}" in the notification. Confirm below.',
              style: t.bodySmall),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: FilledButton(
              key: const Key('approve'),
              onPressed: canAnswer ? widget.onAllow : null,
              child: const Text('Approve'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              key: const Key('deny'),
              onPressed: canAnswer ? widget.onDeny : null,
              child: const Text('Deny'),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _text,
          enabled: canAnswer,
          minLines: 1,
          maxLines: 5,
          maxLength: 4096,
          decoration: const InputDecoration(labelText: 'Reply to the agent'),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: canAnswer ? () => widget.onText(_text.text) : null,
            child: const Text('Send reply'),
          ),
        ),
        const Divider(),
        TextButton.icon(onPressed: widget.onOpenTerminal, icon: const Icon(Icons.terminal), label: const Text('Open terminal')),
        if (widget.busy) const LinearProgressIndicator(),
      ],
    );
  }
}
