import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../voice/presentation/containers/voice_mic_button.dart';
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
        onAppLockChanged: (v) => _toggleLock(context, ref, v),
        onOpenColors: () => context.push('/settings/colors'),
        onOpenVoice: () => context.push(voiceSettingsRoute),
      ),
    );
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref, bool enable) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    final why = await ref.read(appLockProvider).verifyToggle(enable: enable);
    if (why != null) {
      messenger.showSnackBar(SnackBar(content: Text(l.failureMessage(why))));
      return;
    }
    final current = ref.read(settingsProvider).value ?? const AppSettings();
    await ref.read(settingsRepositoryProvider).save(current.copyWith(appLock: enable));
  }
}
