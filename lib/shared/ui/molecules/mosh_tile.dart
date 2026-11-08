import 'package:flutter/material.dart';

import '../tokens/mosh_colors.dart';

/// Tile tones: a plain card, the accent (primary action) or the inverse
/// neutral (selected / main secondary action).
enum TileTone { card, raised, accent, inverse }

/// Rounded, tappable UI-G card. At least 48 px tall.
class MoshTile extends StatelessWidget {
  const MoshTile({
    super.key,
    required this.child,
    this.onTap,
    this.tone = TileTone.card,
    this.radius = MoshRadii.card,
    this.padding = const EdgeInsets.all(18),
    this.height,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final TileTone tone;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double? height;
  final String? semanticLabel;

  /// Reported to screen readers when the tile is one choice of a group.
  final bool? selected;

  static (Color, Color) colors(MoshColors c, TileTone tone) => switch (tone) {
    TileTone.card => (c.surface, c.foreground),
    TileTone.raised => (c.surfaceHigh, c.foreground),
    TileTone.accent => (c.accent, c.onAccent),
    TileTone.inverse => (c.inverse, c.onInverse),
  };

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final (bg, fg) = colors(c, tone);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
    Widget body = DefaultTextStyle.merge(
      style: TextStyle(color: fg),
      child: IconTheme.merge(
        data: IconThemeData(color: fg),
        child: Padding(padding: padding, child: child),
      ),
    );
    body = ConstrainedBox(
      constraints: BoxConstraints(minHeight: height ?? 48),
      child: height == null ? body : SizedBox(height: height, child: body),
    );
    return Semantics(
      label: semanticLabel,
      selected: selected,
      button: onTap != null,
      container: true,
      child: Material(
        color: bg,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? body : InkWell(onTap: onTap, customBorder: shape, child: body),
      ),
    );
  }
}
