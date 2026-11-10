import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/voice_model.dart';
import '../../domain/entities/voice_selection.dart';
import '../controllers/voice_models_controller.dart';
import '../views/custom_model_dialog.dart';
import '../views/voice_settings_view.dart';

class VoiceSettingsContainer extends ConsumerWidget {
  const VoiceSettingsContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value ?? const AppSettings();
    final state = ref.watch(voiceModelsControllerProvider);
    final c = ref.read(voiceModelsControllerProvider.notifier);
    return Scaffold(
      body: VoiceSettingsView(
        models: allVoiceModels(s),
        state: state,
        selectedId: s.voiceModelId,
        language: s.voiceLanguage,
        onBack: () => context.canPop() ? context.pop() : context.go('/settings'),
        onDownload: (m) => unawaited(_download(context, c, m)),
        onCancel: c.cancel,
        onDelete: (m) => unawaited(_delete(context, c, m)),
        onSelect: (id) => unawaited(c.select(id)),
        onLanguage: (code) => unawaited(c.setLanguage(code)),
        onAddCustom: () => unawaited(_addCustom(context, c)),
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
            FilledButton(
              key: const Key('voice_confirm'),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  /// The size is shown and confirmed before a single byte is fetched.
  Future<void> _download(BuildContext context, VoiceModelsController c, VoiceModel m) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final host = Uri.parse(m.url).host;
    final size = m.sizeBytes;
    final ok = await _confirm(
      context,
      l.voiceDownloadTitle(m.name),
      size == null
          ? l.voiceDownloadBodyUnknown(host)
          : l.voiceDownloadBody(formatBytes(size), host),
      l.voiceDownload,
    );
    if (!ok) return;
    final outcome = await c.download(m);
    final text = switch (outcome) {
      DownloadOutcome.done => l.voiceReady(m.name),
      DownloadOutcome.cancelled => null,
      DownloadOutcome.checksum => l.voiceChecksum,
      DownloadOutcome.missingFiles => l.voiceMissingFiles,
      DownloadOutcome.unsafe => l.voiceUnsafe,
      DownloadOutcome.failed => l.voiceDownloadFailed,
    };
    if (text != null) messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _delete(BuildContext context, VoiceModelsController c, VoiceModel m) async {
    final l = context.l10n;
    final ok = await _confirm(
      context,
      l.voiceDeleteTitle(m.name),
      m.custom ? l.voiceDeleteCustomBody : l.voiceDeleteBody,
      l.delete,
    );
    if (ok) await c.delete(m);
  }

  Future<void> _addCustom(BuildContext context, VoiceModelsController c) async {
    final model = await showDialog<VoiceModel>(
      context: context,
      builder: (_) => const CustomModelDialog(newId: newId),
    );
    if (model != null) await c.addCustom(model);
  }
}
