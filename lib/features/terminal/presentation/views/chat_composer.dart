import 'package:flutter/material.dart';

import '../../../../shared/ui/tokens/mosh_colors.dart';
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
    final c = MoshColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(MoshRadii.card),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.attachments.isNotEmpty)
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
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
                    style: IconButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: c.onAccent,
                      fixedSize: const Size(48, 48),
                    ),
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
          borderRadius: BorderRadius.circular(16),
          child: SizedBox.square(
            dimension: 56,
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
        // 44 px touch target around a small visible badge.
        Positioned(
          top: -12,
          right: -12,
          child: Tooltip(
            message: 'Remove ${attachment.name}',
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: scheme.inverseSurface,
                    child: Icon(Icons.close, size: 13, color: scheme.onInverseSurface),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
