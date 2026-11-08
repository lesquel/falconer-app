import 'package:flutter/material.dart';

/// UI-G color tokens: black and white surfaces plus one accent.
///
/// Every text color here passes WCAG 2.2 AA (4.5:1) on [background],
/// [surface] and [surfaceHigh]; see test/app/theme_contrast_test.dart.
@immutable
class MoshColors extends ThemeExtension<MoshColors> {
  const MoshColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceHigh,
    required this.foreground,
    required this.muted,
    required this.outline,
    required this.accent,
    required this.onAccent,
    required this.inverse,
    required this.onInverse,
    required this.danger,
  });

  factory MoshColors.dark({required Color accent, required Color onAccent}) => MoshColors(
    isDark: true,
    background: const Color(0xFF0A0A0A),
    surface: const Color(0xFF171717),
    surfaceHigh: const Color(0xFF262626),
    foreground: const Color(0xFFFAFAFA),
    muted: const Color(0xFFA3A3A3),
    outline: const Color(0xFF525252),
    accent: accent,
    onAccent: onAccent,
    inverse: const Color(0xFFFAFAFA),
    onInverse: const Color(0xFF0A0A0A),
    danger: const Color(0xFFFF8A80),
  );

  factory MoshColors.light({required Color accent, required Color onAccent}) => MoshColors(
    isDark: false,
    background: const Color(0xFFFAFAFA),
    surface: const Color(0xFFF0F0F0),
    surfaceHigh: const Color(0xFFE3E3E3),
    foreground: const Color(0xFF0A0A0A),
    muted: const Color(0xFF525252),
    outline: const Color(0xFF8F8F8F),
    accent: accent,
    onAccent: onAccent,
    inverse: const Color(0xFF0A0A0A),
    onInverse: const Color(0xFFFAFAFA),
    danger: const Color(0xFFB3261E),
  );

  final bool isDark;
  final Color background;

  /// Cards (#171717 on dark).
  final Color surface;

  /// Cards inside cards and secondary buttons (#262626 on dark).
  final Color surfaceHigh;
  final Color foreground;

  /// Secondary text.
  final Color muted;

  /// Decorative borders only (dashed "add" tiles); never used for text.
  final Color outline;
  final Color accent;
  final Color onAccent;

  /// The selected / primary neutral tile: white on dark, black on light.
  final Color inverse;
  final Color onInverse;
  final Color danger;

  static MoshColors of(BuildContext context) =>
      Theme.of(context).extension<MoshColors>() ??
      MoshColors.dark(accent: const Color(0xFF6B93FF), onAccent: Colors.black);

  @override
  MoshColors copyWith({Color? accent, Color? onAccent}) => MoshColors(
    isDark: isDark,
    background: background,
    surface: surface,
    surfaceHigh: surfaceHigh,
    foreground: foreground,
    muted: muted,
    outline: outline,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    inverse: inverse,
    onInverse: onInverse,
    danger: danger,
  );

  @override
  MoshColors lerp(MoshColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return MoshColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      foreground: l(foreground, other.foreground),
      muted: l(muted, other.muted),
      outline: l(outline, other.outline),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      inverse: l(inverse, other.inverse),
      onInverse: l(onInverse, other.onInverse),
      danger: l(danger, other.danger),
    );
  }
}

/// Corner radii of the UI-G system.
abstract final class MoshRadii {
  static const tile = 22.0;
  static const card = 26.0;
  static const hero = 30.0;
  static const key = 18.0;
}
