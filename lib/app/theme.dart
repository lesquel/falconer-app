import 'package:flutter/material.dart';

import '../features/settings/domain/entities/appearance.dart';
import '../shared/ui/tokens/mosh_colors.dart';

/// UI-G tokens for one brightness and accent.
MoshColors moshColors(Brightness brightness, AccentColor accent) {
  final dark = brightness == Brightness.dark;
  final a = Color(accent.forDark(dark));
  final on = Color(accent.onAccent(dark));
  return dark
      ? MoshColors.dark(accent: a, onAccent: on)
      : MoshColors.light(accent: a, onAccent: on);
}

ThemeData buildTheme(Brightness brightness, {AccentColor accent = AccentColor.blue}) {
  final c = moshColors(brightness, accent);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    primaryContainer: c.accent,
    onPrimaryContainer: c.onAccent,
    secondary: c.inverse,
    onSecondary: c.onInverse,
    secondaryContainer: c.surfaceHigh,
    onSecondaryContainer: c.foreground,
    tertiary: c.accent,
    onTertiary: c.onAccent,
    tertiaryContainer: c.accent,
    onTertiaryContainer: c.onAccent,
    error: c.danger,
    onError: c.isDark ? Colors.black : Colors.white,
    errorContainer: c.surfaceHigh,
    onErrorContainer: c.danger,
    surface: c.background,
    onSurface: c.foreground,
    onSurfaceVariant: c.muted,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceHigh,
    surfaceContainerHighest: c.surfaceHigh,
    outline: c.outline,
    outlineVariant: c.surfaceHigh,
    inverseSurface: c.inverse,
    onInverseSurface: c.onInverse,
    inversePrimary: c.accent,
  );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: 'Manrope');
  final t = base.textTheme;
  const tight = -0.6;
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.key));
  const tall = Size(64, 52);
  return base.copyWith(
    extensions: [c],
    scaffoldBackgroundColor: c.background,
    textTheme: t.copyWith(
      displaySmall: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: tight),
      headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: tight),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: tight),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: c.background,
      foregroundColor: c.foreground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: t.titleLarge?.copyWith(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w800,
        color: c.foreground,
      ),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.card)),
    ),
    listTileTheme: ListTileThemeData(
      minVerticalPadding: 12,
      iconColor: c.foreground,
      textColor: c.foreground,
      subtitleTextStyle: TextStyle(color: c.muted, fontFamily: 'Manrope'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.tile)),
    ),
    // Explicit colors: the default dark filled button rendered without a readable label.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        iconColor: c.onAccent,
        disabledBackgroundColor: c.surfaceHigh,
        disabledForegroundColor: c.muted,
        minimumSize: tall,
        shape: pill,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.foreground,
        backgroundColor: c.surfaceHigh,
        disabledForegroundColor: c.muted,
        side: BorderSide.none,
        minimumSize: tall,
        shape: pill,
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: c.foreground,
        minimumSize: const Size(48, 48),
        shape: pill,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: c.foreground),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      labelStyle: TextStyle(color: c.muted),
      helperStyle: TextStyle(color: c.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoshRadii.key),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MoshRadii.key),
        borderSide: BorderSide(color: c.foreground, width: 2),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.onAccent : c.muted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
      ),
      // A check in the thumb: the state is never shown by color alone.
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Icon(Icons.check, size: 16, color: c.accent)
            : Icon(Icons.close, size: 16, color: c.surfaceHigh),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: c.accent,
      thumbColor: c.accent,
      inactiveTrackColor: c.surfaceHigh,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      dragHandleColor: c.muted,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MoshRadii.hero)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.card)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: c.inverse,
      contentTextStyle: TextStyle(color: c.onInverse, fontFamily: 'Manrope'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.key)),
    ),
    dividerTheme: DividerThemeData(color: c.surfaceHigh, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: c.accent),
  );
}

ThemeMode themeModeFor(ThemePreference p) => switch (p) {
  ThemePreference.system => ThemeMode.system,
  ThemePreference.light => ThemeMode.light,
  ThemePreference.dark => ThemeMode.dark,
};
