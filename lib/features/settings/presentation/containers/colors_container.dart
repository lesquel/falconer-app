import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../domain/entities/app_settings.dart';
import '../views/colors_view.dart';

class ColorsContainer extends ConsumerWidget {
  const ColorsContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    return Scaffold(
      body: ColorsView(
        settings: s,
        onChanged: ref.read(settingsRepositoryProvider).save,
        onBack: () => context.canPop() ? context.pop() : context.go('/settings'),
      ),
    );
  }
}
