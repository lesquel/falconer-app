import 'package:flutter/material.dart';

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
    return AlertDialog(
      title: const Text('Add shortcut'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Ctrl + key')),
              ButtonSegment(value: false, label: Text('Text')),
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
              labelText: _ctrl ? 'Letter' : 'Text to send',
              hintText: _ctrl ? 'C' : 'git status',
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (!_ctrl) ...[
            TextField(
              controller: _label,
              decoration: const InputDecoration(labelText: 'Label (optional)'),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _enter,
              title: const Text('Press Enter after the text'),
              onChanged: (v) => setState(() => _enter = v ?? false),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: key == null ? null : () => Navigator.of(context).pop(key),
          child: Text(key == null ? 'Add' : 'Add ${key.label}'),
        ),
      ],
    );
  }
}
