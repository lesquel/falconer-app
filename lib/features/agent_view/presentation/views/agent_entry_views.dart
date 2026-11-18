import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/agent_entry.dart';

const _mono = 'monospace';

/// Output lines a card shows before "show more".
const collapsedOutputLines = 3;

/// One item of the conversation, drawn by what it is.
class AgentEntryView extends StatelessWidget {
  const AgentEntryView(this.entry, {super.key});
  final AgentEntry entry;

  @override
  Widget build(BuildContext context) => switch (entry) {
    final UserEntry e => _UserBubble(e),
    final MessageEntry e => _Message(e),
    final CommandEntry e => _CommandCard(e),
    final EditEntry e => _EditCard(e),
    final ActivityEntry e => _ActivityRow(e),
    final OutputEntry e => _Card(child: _Output(e.lines)),
    final ThinkingEntry e => _Thinking(e),
    final ErrorEntry e => _ErrorCard(e),
  };
}

class _UserBubble extends StatelessWidget {
  const _UserBubble(this.entry);
  final UserEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Material(
          color: c.accent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: SelectableText(
              entry.text,
              style: TextStyle(
                color: c.onAccent,
                fontSize: 15,
                height: 21 / 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The agent's reply: plain text on the background, no container.
class _Message extends StatelessWidget {
  const _Message(this.entry);
  final MessageEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final style = TextStyle(color: c.foreground, fontSize: 15, height: 22 / 15);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, s) in entry.segments.indexed)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 6),
                child: _segment(context, s, style),
              ),
          ],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, MessageSegment s, TextStyle style) {
    final c = MoshColors.of(context);
    final text = SelectableText.rich(inlineSpans(s.text, style, c));
    return switch (s.kind) {
      SegmentKind.paragraph => text,
      SegmentKind.preformatted => _Well(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            s.text,
            style: TextStyle(fontFamily: _mono, fontSize: 12, height: 18 / 12, color: c.foreground),
          ),
        ),
      ),
      SegmentKind.bullet || SegmentKind.numbered => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            child: Text(s.marker ?? '•', style: style.copyWith(color: c.muted)),
          ),
          Expanded(child: text),
        ],
      ),
    };
  }
}

final _inline = RegExp(r'`([^`]+)`|\*\*([^*]+)\*\*');

/// [text] with `code` and **bold** drawn as such.
TextSpan inlineSpans(String text, TextStyle style, MoshColors c) {
  final spans = <InlineSpan>[];
  var at = 0;
  for (final m in _inline.allMatches(text)) {
    if (m.start > at) spans.add(TextSpan(text: text.substring(at, m.start)));
    final code = m[1];
    spans.add(
      code != null
          ? TextSpan(
              text: code,
              style: TextStyle(fontFamily: _mono, fontSize: 13, backgroundColor: c.surfaceHigh),
            )
          : TextSpan(
              text: m[2],
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
    );
    at = m.end;
  }
  if (at < text.length) spans.add(TextSpan(text: text.substring(at)));
  return TextSpan(style: style, children: spans);
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.surfaceHigh),
      ),
      child: child,
    );
  }
}

class _Well extends StatelessWidget {
  const _Well({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: MoshColors.of(context).background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label, this.trailing});
  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          Icon(icon, size: 15, color: c.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard(this.entry);
  final CommandEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final (String? state, Color color, IconData? icon) = switch (entry.state) {
      CommandState.running => (l.agentViewStateRunning, c.muted, Icons.more_horiz),
      CommandState.failed => (l.agentViewStateFailed, c.danger, Icons.close),
      CommandState.unknown => (null, c.muted, null),
    };
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            icon: Icons.terminal,
            label: l.agentViewCommand,
            trailing: state == null
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        state,
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: SelectableText.rich(
              TextSpan(
                style: TextStyle(
                  fontFamily: _mono,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w600,
                  color: c.foreground,
                ),
                children: [
                  TextSpan(
                    text: r'$ ',
                    style: TextStyle(color: c.muted),
                  ),
                  TextSpan(text: entry.command),
                ],
              ),
            ),
          ),
          if (entry.output.isNotEmpty) _Output(entry.output),
        ],
      ),
    );
  }
}

/// Monospace output: the first lines, the rest behind "show more". The open
/// state survives scrolling the card out of view.
class _Output extends StatefulWidget {
  const _Output(this.lines);
  final List<String> lines;

  @override
  State<_Output> createState() => _OutputState();
}

class _OutputState extends State<_Output> with AutomaticKeepAliveClientMixin {
  bool _open = false;

  @override
  bool get wantKeepAlive => _open;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = MoshColors.of(context);
    final l = context.l10n;
    final lines = widget.lines;
    final hidden = lines.length - collapsedOutputLines;
    final shown = _open || hidden <= 0 ? lines : lines.take(collapsedOutputLines);
    return ColoredBox(
      color: c.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: SelectableText(
              shown.join('\n'),
              style: TextStyle(fontFamily: _mono, fontSize: 12, height: 18 / 12, color: c.muted),
            ),
          ),
          if (hidden > 0)
            TextButton(
              key: const Key('agent-output-toggle'),
              style: TextButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                foregroundColor: c.foreground,
                textStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                shape: const RoundedRectangleBorder(),
              ),
              onPressed: () => setState(() {
                _open = !_open;
                updateKeepAlive();
              }),
              child: Text(_open ? l.agentViewShowLess : l.agentViewShowMore(hidden)),
            ),
        ],
      ),
    );
  }
}

class _EditCard extends StatelessWidget {
  const _EditCard(this.entry);
  final EditEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    const style = TextStyle(fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w700);
    final added = entry.added;
    final removed = entry.removed;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            icon: Icons.edit_outlined,
            label: context.l10n.agentViewEdit,
            trailing: added == null && removed == null && !entry.failed
                ? null
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (entry.failed) ...[
                        Icon(Icons.close, size: 14, color: c.danger),
                        const SizedBox(width: 4),
                        Text(
                          context.l10n.agentViewStateFailed,
                          style: TextStyle(
                            color: c.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (added != null) Text('+$added', style: style.copyWith(color: c.success)),
                      const SizedBox(width: 6),
                      if (removed != null)
                        Text('−$removed', style: style.copyWith(color: c.danger)),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: SelectableText(
              entry.path,
              style: TextStyle(fontFamily: _mono, fontSize: 13, color: c.foreground),
            ),
          ),
          if (entry.notes.isNotEmpty) _Output(entry.notes),
          for (final row in entry.diff) _DiffLine(row),
        ],
      ),
    );
  }
}

class _DiffLine extends StatelessWidget {
  const _DiffLine(this.row);
  final DiffRow row;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final (String sign, Color fg, Color bg) = switch (row.kind) {
      DiffKind.added => ('+', c.diffAddFg, c.diffAddBg),
      DiffKind.removed => ('−', c.diffRemoveFg, c.diffRemoveBg),
      DiffKind.context => (' ', c.muted, c.background),
    };
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '$sign ${row.text}',
          style: TextStyle(fontFamily: _mono, fontSize: 12, height: 20 / 12, color: fg),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(this.entry);
  final ActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final failed = entry.failed;
    final icon = switch (entry.kind) {
      _ when failed => Icons.error_outline,
      ActivityKind.read => Icons.description_outlined,
      ActivityKind.search => Icons.search,
      ActivityKind.other => Icons.build_outlined,
    };
    final style = TextStyle(color: c.muted, fontSize: 13, height: 18 / 13);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 15, color: c.muted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText([entry.label, ...entry.detail].join('\n'), style: style),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thinking extends StatelessWidget {
  const _Thinking(this.entry);
  final ThinkingEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Row(
        children: [
          Icon(Icons.blur_circular, size: 15, color: c.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.text,
              style: TextStyle(color: c.muted, fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.entry);
  final ErrorEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final detail = entry.detail;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: c.dangerSurface, borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: c.danger, child: const SizedBox(width: 4)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, size: 18, color: c.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            entry.title,
                            style: TextStyle(
                              color: c.foreground,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (detail != null) ...[
                            const SizedBox(height: 4),
                            SelectableText(
                              detail,
                              style: TextStyle(color: c.foreground, fontSize: 13, height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
