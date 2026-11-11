import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/herdr_snapshot.dart';

/// Header and loading/error states shared by the Herdr screens. [builder]
/// draws the body once a snapshot arrived; a later error only adds a
/// "showing the last state" line above it.
class HerdrFrame extends StatelessWidget {
  const HerdrFrame({
    super.key,
    required this.title,
    required this.snapshot,
    required this.onRetry,
    required this.builder,
    this.subtitle,
    this.error,
    this.onBack,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final HerdrSnapshot? snapshot;
  final Object? error;
  final VoidCallback onRetry;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget Function(BuildContext context, HerdrSnapshot snapshot) builder;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final snap = snapshot;
    final Widget body;
    if (snap == null) {
      body = error != null
          ? FailurePanel(failure: error!, onRetry: onRetry)
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(l.herdrLoading),
                ],
              ),
            );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                l.herdrOutOfDate,
                key: const Key('herdr-stale'),
                style: TextStyle(color: c.muted, fontSize: 12),
              ),
            ),
          Expanded(child: builder(context, snap)),
        ],
      );
    }
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                if (onBack != null) ...[
                  CircleIconButton(icon: Icons.chevron_left, tooltip: l.back, onPressed: onBack),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: TextStyle(fontSize: 12, color: c.muted)),
                    ],
                  ),
                ),
                if (snap != null) ...actions,
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Marks the workspace, tab or pane the computer shows.
class HerdrFocusedMark extends StatelessWidget {
  const HerdrFocusedMark({super.key});

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_outlined, size: 14, color: c.muted),
          const SizedBox(width: 4),
          Text(context.l10n.herdrFocused, style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }
}

/// A popup menu of labelled callbacks.
class HerdrMenu extends StatelessWidget {
  const HerdrMenu({super.key, required this.items});
  final List<(String, VoidCallback)> items;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: context.l10n.herdrMoreActions,
    onSelected: (f) => f(),
    itemBuilder: (_) => [
      for (final (label, f) in items) PopupMenuItem(value: f, child: Text(label)),
    ],
  );
}
