import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../atoms/circle_icon_button.dart';
import '../tokens/mosh_colors.dart';

/// UI-G page: a small top bar, then a big title and the content pushed to
/// the bottom of the screen, where the thumb reaches. Scrolls when taller
/// than the screen.
class ThumbPage extends StatelessWidget {
  const ThumbPage({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.onBack,
    this.backIcon = Icons.chevron_left,
    this.backTooltip,
    this.caption,
    this.captionChild,
    this.actions = const [],
    this.children = const [],
    this.bottomGap = 24,
  });

  /// Big headline. A [Widget] lets callers highlight part of it.
  final Widget title;
  final String? eyebrow;
  final String? subtitle;
  final VoidCallback? onBack;
  final IconData backIcon;

  /// Defaults to the localized "Back".
  final String? backTooltip;

  /// Small text on the right of the top bar.
  final String? caption;

  /// Replaces [caption] with a widget (a masked address with its eye).
  final Widget? captionChild;
  final List<Widget> actions;
  final List<Widget> children;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final t = Theme.of(context).textTheme;
    final hasBar = onBack != null || caption != null || captionChild != null || actions.isNotEmpty;
    final bar = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
      child: Row(
        children: [
          if (onBack != null)
            CircleIconButton(
              icon: backIcon,
              tooltip: backTooltip ?? context.l10n.back,
              onPressed: onBack,
            ),
          const Spacer(),
          if (captionChild != null)
            Flexible(flex: 6, child: captionChild!)
          else if (caption != null)
            Flexible(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  caption!,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.bodySmall?.copyWith(color: c.muted),
                ),
              ),
            ),
          ...actions,
        ],
      ),
    );
    final body = Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) Text(eyebrow!, style: t.bodyMedium?.copyWith(color: c.muted)),
                const SizedBox(height: 4),
                DefaultTextStyle.merge(
                  style: t.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1,
                    color: c.foreground,
                  ),
                  child: Semantics(header: true, child: title),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(subtitle!, style: t.bodyMedium?.copyWith(color: c.muted)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
    );
    // A min-height column pushes the content to the bottom without intrinsic
    // measurements, and scrolls when it is taller than the screen.
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [if (hasBar) bar else const SizedBox.shrink(), body],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small bold label above a group of tiles.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: MoshColors.of(context).muted, fontWeight: FontWeight.w700),
    ),
  );
}
