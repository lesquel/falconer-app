import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/settings/domain/entities/app_settings.dart';
import 'di.dart';
import 'theme.dart';

class OpenMoshApp extends ConsumerWidget {
  const OpenMoshApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    return MaterialApp.router(
      title: 'OpenMosh',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, accent: s.accent),
      darkTheme: buildTheme(Brightness.dark, accent: s.accent),
      themeMode: themeModeFor(s.themePreference),
      routerConfig: router,
    );
  }
}
