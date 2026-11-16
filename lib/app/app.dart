import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/lock/presentation/app_lock_gate.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../l10n/l10n.dart';
import 'di.dart';
import 'theme.dart';

class FalconerApp extends ConsumerWidget {
  const FalconerApp({super.key, required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final s = settings.value ?? const AppSettings();
    // Until settings load, the gate shows nothing; a failed load locks.
    final lockEnabled = settings.hasValue ? s.appLock : (settings.hasError ? true : null);
    return MaterialApp.router(
      title: 'Falconer',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, accent: s.accent),
      darkTheme: buildTheme(Brightness.dark, accent: s.accent),
      themeMode: themeModeFor(s.themePreference),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      // `system` leaves it null: the phone decides, English when unsupported.
      locale: localeFor(s.language),
      routerConfig: router,
      builder: (context, child) => AppLockGate(
        lock: ref.watch(appLockProvider),
        enabled: lockEnabled,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
