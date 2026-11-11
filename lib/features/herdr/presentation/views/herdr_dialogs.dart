import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/entities/herdr_action.dart';

/// Closing a workspace or tab stops what runs in it, so it is confirmed.
Future<bool> confirmHerdrClose(BuildContext context, String title) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(c.l10n.herdrCloseBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(c.l10n.cancel)),
          FilledButton(
            key: const Key('herdr-confirm-close'),
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.l10n.close),
          ),
        ],
      ),
    ) ==
    true;

/// Asks for a name. Null when cancelled; an empty string only when
/// [optional] (Herdr then picks the name).
Future<String?> askHerdrLabel(
  BuildContext context, {
  required String title,
  required String action,
  String initial = '',
  bool optional = false,
}) => showDialog<String>(
  context: context,
  builder: (c) => _LabelDialog(title: title, action: action, initial: initial, optional: optional),
);

class _LabelDialog extends StatefulWidget {
  const _LabelDialog({
    required this.title,
    required this.action,
    required this.initial,
    required this.optional,
  });
  final String title;
  final String action;
  final String initial;
  final bool optional;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _valid => widget.optional || _text.text.trim().isNotEmpty;

  void _submit() {
    if (_valid) Navigator.pop(context, _text.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        key: const Key('herdr-label'),
        controller: _text,
        autofocus: true,
        maxLength: 64,
        decoration: InputDecoration(labelText: widget.optional ? l.herdrNameOptional : l.herdrName),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          key: const Key('herdr-label-ok'),
          onPressed: _valid ? _submit : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}

/// The agents the hook can start, as a bottom sheet.
Future<String?> pickHerdrAgent(BuildContext context) => showModalBottomSheet<String>(
  context: context,
  showDragHandle: true,
  builder: (c) => SafeArea(
    child: ListView(
      shrinkWrap: true,
      children: [
        ListTile(
          title: Text(c.l10n.herdrStartAgent, style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        for (final a in startableAgents)
          ListTile(
            key: Key('agent-$a'),
            leading: const Icon(Icons.smart_toy_outlined),
            title: Text(a),
            onTap: () => Navigator.pop(c, a),
          ),
      ],
    ),
  ),
);
