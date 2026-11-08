import 'package:flutter/material.dart';

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D6B), brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: const AppBarTheme(centerTitle: false),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    // Explicit colors: the default dark filled button rendered without a readable label.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        iconColor: scheme.onPrimary,
      ),
    ),
  );
}
