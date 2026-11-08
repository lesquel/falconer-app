import 'package:flutter/material.dart';

/// Chat-style input: write (or dictate with the keyboard's mic) a whole
/// message, then send it to the terminal as one paste followed by Enter.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.initialText,
    required this.onSend,
    required this.onChanged,
    required this.onAttach,
    required this.onClose,
    this.busy = false,
  });

  final String initialText;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onChanged;

  /// Returns text to insert at the cursor (uploaded paths), or null.
  final Future<String?> Function() onAttach;
  final VoidCallback onClose;
  final bool busy;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  late final _text = TextEditingController(text: widget.initialText);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _send() {
    final t = _text.text;
    if (t.trim().isEmpty) return;
    widget.onSend(t);
    _text.clear();
    widget.onChanged('');
  }

  Future<void> _attach() async {
    final insert = await widget.onAttach();
    if (insert == null || insert.isEmpty || !mounted) return;
    final sel = _text.selection;
    final at = sel.isValid ? sel.start : _text.text.length;
    final end = sel.isValid ? sel.end : at;
    final before = _text.text.substring(0, at);
    final sep = before.isEmpty || before.endsWith(' ') ? '' : ' ';
    final next = '$before$sep$insert ${_text.text.substring(end)}';
    _text.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: before.length + sep.length + insert.length + 1),
    );
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              tooltip: 'Attach images or files',
              icon: const Icon(Icons.add),
              onPressed: widget.busy ? null : _attach,
            ),
            Expanded(
              child: TextField(
                key: const Key('chat-input'),
                controller: _text,
                autofocus: true,
                minLines: 1,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                onChanged: widget.onChanged,
                decoration: const InputDecoration(hintText: 'Message the agent…', isDense: true),
              ),
            ),
            IconButton(
              tooltip: 'Close chat',
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
            IconButton.filled(
              tooltip: 'Send',
              icon: const Icon(Icons.arrow_upward),
              onPressed: widget.busy ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
