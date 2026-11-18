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
    required this.success,
    required this.warning,
    required this.warningSurface,
    required this.onWarning,
    required this.dangerSurface,
    required this.diffAddFg,
    required this.diffAddBg,
    required this.diffRemoveFg,
    required this.diffRemoveBg,
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
    success: const Color(0xFF6EDC9A),
    warning: const Color(0xFFFFC061),
    warningSurface: const Color(0xFF2A2010),
    onWarning: const Color(0xFF0A0A0A),
    dangerSurface: const Color(0xFF2B1513),
    diffAddFg: const Color(0xFF86EFAC),
    diffAddBg: const Color(0xFF10301E),
    diffRemoveFg: const Color(0xFFFFB4AB),
    diffRemoveBg: const Color(0xFF3B1717),
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
    success: const Color(0xFF146C3A),
    warning: const Color(0xFF7A4A00),
    warningSurface: const Color(0xFFFFF1D6),
    onWarning: const Color(0xFFFFFFFF),
    dangerSurface: const Color(0xFFFBE4E1),
    diffAddFg: const Color(0xFF0E5A2E),
    diffAddBg: const Color(0xFFD3F1DD),
    diffRemoveFg: const Color(0xFF8C1D18),
    diffRemoveBg: const Color(0xFFFBDAD6),
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

  /// A command that finished well.
  final Color success;

  /// Whatever waits on the user: permissions and questions.
  final Color warning;
  final Color warningSurface;
  final Color onWarning;
  final Color dangerSurface;

  /// Added and removed rows of a file diff.
  final Color diffAddFg;
  final Color diffAddBg;
  final Color diffRemoveFg;
  final Color diffRemoveBg;

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
    success: success,
    warning: warning,
    warningSurface: warningSurface,
    onWarning: onWarning,
    dangerSurface: dangerSurface,
    diffAddFg: diffAddFg,
    diffAddBg: diffAddBg,
    diffRemoveFg: diffRemoveFg,
    diffRemoveBg: diffRemoveBg,
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
      success: l(success, other.success),
      warning: l(warning, other.warning),
      warningSurface: l(warningSurface, other.warningSurface),
      onWarning: l(onWarning, other.onWarning),
      dangerSurface: l(dangerSurface, other.dangerSurface),
      diffAddFg: l(diffAddFg, other.diffAddFg),
      diffAddBg: l(diffAddBg, other.diffAddBg),
      diffRemoveFg: l(diffRemoveFg, other.diffRemoveFg),
      diffRemoveBg: l(diffRemoveBg, other.diffRemoveBg),
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
