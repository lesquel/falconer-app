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
    final dark = (ref.watch(settingsProvider).value ?? const AppSettings()).darkTheme;
    return MaterialApp.router(
      title: 'OpenMosh',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
    );
  }
}
