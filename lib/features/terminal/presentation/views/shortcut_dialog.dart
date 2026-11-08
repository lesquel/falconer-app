import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../keyboard/domain/entities/custom_keys.dart';
import '../../../keyboard/domain/entities/extra_key.dart';

/// Asks for a new saved shortcut: Ctrl + a letter, or a piece of text.
Future<ExtraKey?> showShortcutDialog(BuildContext context) =>
    showDialog<ExtraKey>(context: context, builder: (_) => const ShortcutDialog());

class ShortcutDialog extends StatefulWidget {
  const ShortcutDialog({super.key});

  @override
  State<ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends State<ShortcutDialog> {
  bool _ctrl = true;
  bool _enter = false;
  final _value = TextEditingController();
  final _label = TextEditingController();

  @override
  void dispose() {
    _value.dispose();
    _label.dispose();
    super.dispose();
  }

  ExtraKey? get _key => _ctrl
      ? CustomKeys.ctrl(_value.text)
      : CustomKeys.text(_value.text, enter: _enter, label: _label.text);

  @override
  Widget build(BuildContext context) {
    final key = _key;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.addShortcut),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: true, label: Text(l.shortcutCtrlKey)),
              ButtonSegment(value: false, label: Text(l.shortcutText)),
            ],
            selected: {_ctrl},
            onSelectionChanged: (v) => setState(() {
              _ctrl = v.first;
              _value.clear();
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('shortcut-value'),
            controller: _value,
            autofocus: true,
            maxLength: _ctrl ? 1 : null,
            textCapitalization: _ctrl ? TextCapitalization.characters : TextCapitalization.none,
            decoration: InputDecoration(
              labelText: _ctrl ? l.shortcutLetter : l.shortcutTextToSend,
              hintText: _ctrl ? 'C' : 'git status',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (!_ctrl) ...[
            TextField(
              controller: _label,
              decoration: InputDecoration(labelText: l.shortcutLabelOptional),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _enter,
              title: Text(l.shortcutPressEnter),
              onChanged: (v) => setState(() => _enter = v ?? false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(
          onPressed: key == null ? null : () => Navigator.of(context).pop(key),
          child: Text(key == null ? l.shortcutAdd : l.shortcutAddNamed(key.label)),
        ),
      ],
    );
  }
}
