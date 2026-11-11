import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/screen_block.dart';

/// Longest label a choice button shows; the full one is in its tooltip and
/// semantics.
const choiceLabelChars = 44;

/// [label] cut at a word to fit a button, with `…` when cut.
String shortChoiceLabel(String label, {int max = choiceLabelChars}) {
  final s = label.trim();
  if (s.length <= max) return s;
  var cut = s.lastIndexOf(' ', max - 1);
  if (cut < max ~/ 2) cut = max - 1;
  return '${s.substring(0, cut).replaceFirst(RegExp(r'[\s,;:.]+$'), '')}…';
}

/// After a sent answer the buttons wait for the next screen; when it never
/// comes (the menu did not change) they enable again after this.
const choiceResendAfter = Duration(seconds: 10);

/// The menu the agent waits on, docked above the composer: who asks, the
/// question, the command or file it is about, and one button per answer.
/// A tap sends the option's keys once; every button stays disabled until a
/// different menu (the next screen) arrives or the send fails.
class PermissionCard extends StatefulWidget {
  const PermissionCard({
    super.key,
    required this.agent,
    required this.block,
    required this.onChoice,
  });

  final String agent;
  final ChoiceBlock block;

  /// Sends the option's keys; a non-null result is a failure.
  final Future<Object?> Function(List<String> keys) onChoice;

  @override
  State<PermissionCard> createState() => _PermissionCardState();
}

class _PermissionCardState extends State<PermissionCard> {
  /// The option being sent; null when the buttons are enabled.
  int? _sending;
  Timer? _resend;

  @override
  void didUpdateWidget(PermissionCard old) {
    super.didUpdateWidget(old);
    if (old.block != widget.block) _enable();
  }

  @override
  void dispose() {
    _resend?.cancel();
    super.dispose();
  }

  void _enable() {
    _resend?.cancel();
    _sending = null;
  }

  Future<void> _choose(int i) async {
    if (_sending != null) return;
    final block = widget.block;
    setState(() => _sending = i);
    unawaited(HapticFeedback.mediumImpact());
    final failure = await widget.onChoice(block.options[i].keys);
    if (!mounted || widget.block != block) return;
    if (failure != null) {
      setState(_enable);
      return;
    }
    _resend?.cancel();
    _resend = Timer(choiceResendAfter, () {
      if (mounted) setState(_enable);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final block = widget.block;
    final permission = block.options.any((o) => o.kind != ChoiceKind.other);
    final detail = block.detail;
    return Container(
      key: const Key('agent-permission-card'),
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(MoshRadii.card),
        border: Border.all(color: c.accent, width: 1.5),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  permission ? Icons.shield_outlined : Icons.help_outline,
                  size: 18,
                  color: c.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    permission
                        ? l.agentViewNeedsPermission(widget.agent)
                        : l.agentViewIsAsking(widget.agent),
                    style: TextStyle(color: c.muted, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Semantics(
              header: true,
              child: Text(
                block.question,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.25),
              ),
            ),
            if (detail != null) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('agent-permission-detail'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: c.surfaceHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  detail,
                  maxLines: 6,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.35,
                    color: c.foreground,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            for (final (i, o) in block.options.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChoiceButton(
                  index: i,
                  option: o,
                  sending: _sending == i,
                  onPressed: _sending == null ? () => unawaited(_choose(i)) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.index,
    required this.option,
    required this.sending,
    required this.onPressed,
  });

  final int index;
  final ChoiceOption option;
  final bool sending;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final short = shortChoiceLabel(option.label);
    final iconData = switch (option.kind) {
      ChoiceKind.allow => Icons.check,
      ChoiceKind.allowAlways => Icons.done_all,
      ChoiceKind.deny => Icons.close,
      ChoiceKind.other => Icons.chevron_right,
    };
    final (Color? bg, Color fg) = switch (option.kind) {
      ChoiceKind.allow => (c.accent, c.onAccent),
      ChoiceKind.allowAlways => (c.surfaceHigh, c.foreground),
      ChoiceKind.deny => (null, c.danger),
      ChoiceKind.other => (null, c.foreground),
    };
    final Widget icon = sending
        ? SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Icon(iconData, size: 20);
    final label = Row(
      children: [
        Expanded(child: Text(short, maxLines: 2, overflow: TextOverflow.ellipsis)),
        if (option.selected)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              key: Key('choice-selected-$index'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
          ),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.key));
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    const size = Size(double.infinity, 52);
    const text = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
    final disabledFg = c.muted;
    final key = Key('choice-$index');
    final Widget button = switch (option.kind) {
      ChoiceKind.allow || ChoiceKind.allowAlways => FilledButton.icon(
        key: key,
        style: FilledButton.styleFrom(
          minimumSize: size,
          padding: padding,
          shape: shape,
          alignment: Alignment.centerLeft,
          textStyle: text,
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: c.surfaceHigh,
          disabledForegroundColor: disabledFg,
        ),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      ChoiceKind.deny => OutlinedButton.icon(
        key: key,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          padding: padding,
          shape: shape,
          alignment: Alignment.centerLeft,
          textStyle: text,
          foregroundColor: fg,
          disabledForegroundColor: disabledFg,
          side: BorderSide(color: onPressed == null ? c.outline : fg, width: 1.5),
        ),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      ChoiceKind.other => TextButton.icon(
        key: key,
        style: TextButton.styleFrom(
          minimumSize: size,
          padding: padding,
          shape: shape,
          alignment: Alignment.centerLeft,
          textStyle: text,
          foregroundColor: fg,
          disabledForegroundColor: disabledFg,
        ),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
    };
    return Semantics(
      label: [
        option.label,
        if (option.selected) l.agentViewCurrentOption,
        if (sending) l.agentViewSending,
      ].join(', '),
      selected: option.selected,
      excludeSemantics: true,
      button: true,
      enabled: onPressed != null,
      onTap: onPressed,
      child: short == option.label ? button : Tooltip(message: option.label, child: button),
    );
  }
}
