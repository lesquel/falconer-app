import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../controllers/chat_attachment.dart';

/// Chat-style input: write (or dictate) a whole message with attached images
/// or files, then send it to the terminal. Dictated text is inserted at the
/// cursor for editing; only the send button sends.
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
    this.micBuilder,
    this.autofocus = true,
    this.compact = false,
  });

  final String initialText;
  final List<ChatAttachment> attachments;
  final ValueChanged<String> onSend;
  final ValueChanged<String> onChanged;

  /// Null hides the attach button (the agent view sends text only).
  final VoidCallback? onAttach;
  final ValueChanged<int> onRemoveAttachment;

  /// Null hides the close button.
  final VoidCallback? onClose;
  final bool busy;

  /// The terminal opens the composer to type at once; the agent view does not.
  final bool autofocus;

  /// One slim row for the agent view: paste moves into the `+` menu.
  final bool compact;

  /// Builds the mic button; it calls the given function with dictated text.
  final Widget Function(ValueChanged<String> insert)? micBuilder;

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

  /// Inserts the phone clipboard at the cursor of the message.
  Future<void> _paste() async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    if (clip == null || clip.isEmpty || !mounted) return;
    _insert(clip);
  }

  /// Replaces the selection (or inserts at the cursor, else at the end).
  void _insert(String insert) {
    final v = _text.value;
    final start = v.selection.isValid ? v.selection.start : v.text.length;
    final end = v.selection.isValid ? v.selection.end : v.text.length;
    final text = v.text.replaceRange(start, end, insert);
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
    widget.onChanged(text);
  }

  /// Dictated words, separated by a space from the text before the cursor.
  void _dictated(String words) {
    if (!mounted || words.isEmpty) return;
    final v = _text.value;
    final at = v.selection.isValid ? v.selection.start : v.text.length;
    final before = at > 0 ? v.text[at - 1] : '';
    _insert(before.isEmpty || before.trim().isEmpty ? words : ' $words');
  }

  void _send() {
    final t = _text.text;
    if (t.trim().isEmpty && widget.attachments.isEmpty) return;
    widget.onSend(t.trim().isEmpty ? '' : t);
    _text.clear();
    widget.onChanged('');
  }

  Widget _compact(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final attach = widget.onAttach;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 6, 10, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.attachments.isNotEmpty)
            SizedBox(
              height: 72,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 4),
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
              PopupMenuButton<_ComposerAction>(
                key: const Key('chat-more'),
                tooltip: l.chatAttach,
                icon: Icon(Icons.add, color: c.muted),
                onSelected: (action) => switch (action) {
                  _ComposerAction.attach => attach?.call(),
                  _ComposerAction.paste => _paste(),
                },
                itemBuilder: (_) => [
                  if (attach != null)
                    PopupMenuItem(
                      value: _ComposerAction.attach,
                      enabled: !widget.busy,
                      child: Text(l.chatAttach),
                    ),
                  PopupMenuItem(
                    key: const Key('chat-paste'),
                    value: _ComposerAction.paste,
                    child: Text(l.paste),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.only(left: 14, right: 4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('chat-input'),
                          controller: _text,
                          autofocus: widget.autofocus,
                          minLines: 1,
                          maxLines: 6,
                          keyboardType: TextInputType.multiline,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: widget.onChanged,
                          decoration: InputDecoration(
                            hintText: l.chatHint,
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      ?widget.micBuilder?.call(_dictated),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton.filled(
                tooltip: l.chatSend,
                style: IconButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  fixedSize: const Size(44, 44),
                  minimumSize: const Size(44, 44),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    if (widget.compact) return _compact(context);
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
                  if (widget.onAttach != null)
                    IconButton(
                      tooltip: l.chatAttach,
                      icon: const Icon(Icons.add),
                      onPressed: widget.busy ? null : widget.onAttach,
                    ),
                  Expanded(
                    child: TextField(
                      key: const Key('chat-input'),
                      controller: _text,
                      autofocus: widget.autofocus,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: widget.onChanged,
                      decoration: InputDecoration(hintText: l.chatHint, isDense: true),
                    ),
                  ),
                  ?widget.micBuilder?.call(_dictated),
                  IconButton(
                    key: const Key('chat-paste'),
                    tooltip: l.paste,
                    icon: const Icon(Icons.content_paste),
                    onPressed: _paste,
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      tooltip: l.chatClose,
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                  IconButton.filled(
                    tooltip: l.chatSend,
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

enum _ComposerAction { attach, paste }

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
            message: context.l10n.chatRemoveAttachment(attachment.name),
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
