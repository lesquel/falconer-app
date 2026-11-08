import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../domain/entities/app_settings.dart';
import '../views/settings_view.dart';

class SettingsContainer extends ConsumerWidget {
  const SettingsContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    return Scaffold(
      body: SettingsView(
        settings: s,
        onChanged: ref.read(settingsRepositoryProvider).save,
        onOpenColors: () => context.push('/settings/colors'),
      ),
    );
  }
}
