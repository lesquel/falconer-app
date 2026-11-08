import 'package:flutter/material.dart';

import '../controllers/chat_attachment.dart';

/// Chat-style input: write (or dictate with the keyboard's mic) a whole
/// message with attached images or files, then send it to the terminal.
class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.initialText,
    required this.attachments,
    required this.onSend,
    required this.onChanged,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onClose,
    this.busy = false,
  });

  final String initialText;
  final List<ChatAttachment> attachments;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onChanged;
  final VoidCallback onAttach;
  final ValueChanged<int> onRemoveAttachment;
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
    if (t.trim().isEmpty && widget.attachments.isEmpty) return;
    widget.onSend(t.trim().isEmpty ? '' : t);
    _text.clear();
    widget.onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.attachments.isNotEmpty)
              SizedBox(
                height: 68,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.attachments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => _Thumb(
                    attachment: widget.attachments[i],
                    onRemove: () => widget.onRemoveAttachment(i),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Attach images or files',
                  icon: const Icon(Icons.add),
                  onPressed: widget.busy ? null : widget.onAttach,
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
                    decoration: const InputDecoration(
                      hintText: 'Message the agent…',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close chat',
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
                IconButton.filled(
                  tooltip: 'Send',
                  icon: widget.busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_upward),
                  onPressed: widget.busy ? null : _send,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.attachment, required this.onRemove});
  final ChatAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final preview = attachment.preview;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox.square(
            dimension: 60,
            child: preview != null
                ? Image.memory(preview, fit: BoxFit.cover, cacheWidth: 180, gaplessPlayback: true)
                : ColoredBox(
                    color: scheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.description_outlined, size: 22),
                          Text(
                            attachment.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Tooltip(
            message: 'Remove ${attachment.name}',
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: scheme.inverseSurface,
                child: Icon(Icons.close, size: 12, color: scheme.onInverseSurface),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
