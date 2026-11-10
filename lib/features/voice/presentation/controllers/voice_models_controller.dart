import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../domain/entities/model_files.dart';
import '../../domain/entities/voice_selection.dart';
import '../../domain/entities/voice_model.dart';
import '../../domain/repositories/voice_ports.dart';

final class ModelDownload {
  const ModelDownload({required this.cancel, this.received = 0, this.total});
  final DownloadCancel cancel;
  final int received;
  final int? total;

  /// 0..1, or null while the size is unknown.
  double? get fraction => (total ?? 0) > 0 ? (received / total!).clamp(0, 1).toDouble() : null;

  /// All bytes are in; the archive is being checked and unpacked.
  bool get unpacking => total != null && received >= total!;
}

final class VoiceModelsState {
  const VoiceModelsState({this.installed, this.downloads = const {}});

  /// Ids of models on the device; null until the folder was read.
  final Set<String>? installed;
  final Map<String, ModelDownload> downloads;

  VoiceModelsState copyWith({Set<String>? installed, Map<String, ModelDownload>? downloads}) =>
      VoiceModelsState(
        installed: installed ?? this.installed,
        downloads: downloads ?? this.downloads,
      );
}

enum DownloadOutcome { done, cancelled, checksum, missingFiles, unsafe, failed }

/// Downloads start only from [download], i.e. from a tap: building this
/// controller only reads which models are already on the device.
class VoiceModelsController extends Notifier<VoiceModelsState> {
  @override
  VoiceModelsState build() {
    unawaited(refresh());
    return const VoiceModelsState();
  }

  ModelStore get _store => ref.read(modelStoreProvider);

  Future<AppSettings> _settings() => ref.read(settingsRepositoryProvider).load();
  Future<void> _save(AppSettings s) => ref.read(settingsRepositoryProvider).save(s);

  Future<void> refresh() async {
    final ids = await _store.installed();
    if (ref.mounted) state = state.copyWith(installed: ids);
  }

  Future<DownloadOutcome> download(VoiceModel model) async {
    if (state.downloads.containsKey(model.id)) return DownloadOutcome.failed;
    final cancel = DownloadCancel();
    void put(ModelDownload? d) {
      if (!ref.mounted) return;
      final map = {...state.downloads}..remove(model.id);
      if (d != null) map[model.id] = d;
      state = state.copyWith(downloads: map);
    }

    put(ModelDownload(cancel: cancel, total: model.sizeBytes));
    try {
      final ready = await _store.download(
        model,
        cancel: cancel,
        onProgress: (r, t) => put(ModelDownload(cancel: cancel, received: r, total: t)),
      );
      final s = await _settings();
      await _save(
        (model.custom
                ? s.copyWith(
                    customVoiceModels: [
                      for (final m in s.customVoiceModels) m.id == ready.id ? ready : m,
                    ],
                  )
                : s)
            .withVoiceModel(s.voiceModelId ?? ready.id),
      );
      return DownloadOutcome.done;
    } on DownloadCancelled {
      return DownloadOutcome.cancelled;
    } on ChecksumMismatch {
      return DownloadOutcome.checksum;
    } on MissingModelFiles {
      return DownloadOutcome.missingFiles;
    } on UnsafeArchive {
      return DownloadOutcome.unsafe;
    } catch (_) {
      return DownloadOutcome.failed;
    } finally {
      put(null);
      await refresh();
    }
  }

  void cancel(String id) => state.downloads[id]?.cancel.cancel();

  /// Frees the disk; a custom model is also removed from the list.
  Future<void> delete(VoiceModel model) async {
    await _store.delete(model.id);
    final s = await _settings();
    await _save(
      s
          .copyWith(
            customVoiceModels: [
              for (final m in s.customVoiceModels)
                if (m.id != model.id) m,
            ],
          )
          .withVoiceModel(s.voiceModelId == model.id ? null : s.voiceModelId),
    );
    await refresh();
  }

  Future<void> select(String id) async {
    final s = await _settings();
    final model = allVoiceModels(s).where((m) => m.id == id).firstOrNull;
    final keepLanguage = model?.selectableLanguages.contains(s.voiceLanguage) ?? false;
    await _save(s.withVoiceModel(id).copyWith(voiceLanguage: keepLanguage ? s.voiceLanguage : ''));
  }

  /// [code] from the model's list, or empty for automatic.
  Future<void> setLanguage(String code) async =>
      _save((await _settings()).copyWith(voiceLanguage: code));

  /// Saves the entry only; downloading it is a separate tap.
  Future<void> addCustom(VoiceModel model) async {
    final s = await _settings();
    await _save(s.copyWith(customVoiceModels: [...s.customVoiceModels, model]));
  }
}

final voiceModelsControllerProvider = NotifierProvider<VoiceModelsController, VoiceModelsState>(
  VoiceModelsController.new,
);
