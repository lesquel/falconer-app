import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../domain/entities/voice_model.dart';
import '../../domain/entities/voice_selection.dart';

enum DictationPhase { idle, recording, transcribing }

sealed class MicOutcome {
  const MicOutcome();
}

/// No usable model: the user must pick or download one first.
final class MicNeedsSetup extends MicOutcome {
  const MicNeedsSetup();
}

final class MicPermissionDenied extends MicOutcome {
  const MicPermissionDenied();
}

final class MicStarted extends MicOutcome {
  const MicStarted();
}

/// Dictated text (possibly empty), for the composer to insert.
final class MicText extends MicOutcome {
  const MicText(this.text);
  final String text;
}

final class MicFailed extends MicOutcome {
  const MicFailed();
}

/// Ignored while a previous tap is still being handled.
final class MicBusy extends MicOutcome {
  const MicBusy();
}

/// Tap to record, tap again to get the text. Recording is capped at
/// [maxRecording] (Whisper decodes 30 s at a time); the caller stops it.
class DictationController extends Notifier<DictationPhase> {
  static const maxRecording = Duration(seconds: 30);

  VoiceModel? _model;
  String _folder = '';
  String _language = '';
  var _starting = false;

  @override
  DictationPhase build() {
    ref.onDispose(() {
      if (_model != null) ref.read(voiceRecorderProvider).cancel();
    });
    return DictationPhase.idle;
  }

  Future<MicOutcome> tap() async {
    switch (state) {
      case DictationPhase.idle:
        return _start();
      case DictationPhase.recording:
        return _finish();
      case DictationPhase.transcribing:
        return const MicBusy();
    }
  }

  Future<MicOutcome> _start() async {
    if (_starting) return const MicBusy();
    _starting = true;
    try {
      final settings = await ref.read(settingsRepositoryProvider).load();
      final model = selectedVoiceModel(settings);
      final store = ref.read(modelStoreProvider);
      if (model == null || model.files.isEmpty || !(await store.installed()).contains(model.id)) {
        return const MicNeedsSetup();
      }
      final recorder = ref.read(voiceRecorderProvider);
      if (!await recorder.requestPermission()) return const MicPermissionDenied();
      _folder = await store.folderOf(model.id);
      _language = settings.voiceLanguage;
      await recorder.start();
      _model = model;
      state = DictationPhase.recording;
      return const MicStarted();
    } catch (_) {
      return const MicFailed();
    } finally {
      _starting = false;
    }
  }

  Future<MicOutcome> _finish() async {
    final model = _model!;
    state = DictationPhase.transcribing;
    try {
      final samples = await ref.read(voiceRecorderProvider).stop();
      _model = null;
      final text = await ref
          .read(speechRecognizerProvider)
          .transcribe(samples, model: model, folder: _folder, language: _language);
      return MicText(text);
    } catch (_) {
      return const MicFailed();
    } finally {
      _model = null;
      if (ref.mounted) state = DictationPhase.idle;
    }
  }

  /// Drops a recording in progress (the composer closed).
  Future<void> cancel() async {
    if (state != DictationPhase.recording) return;
    _model = null;
    state = DictationPhase.idle;
    await ref.read(voiceRecorderProvider).cancel();
  }
}

final dictationControllerProvider = NotifierProvider<DictationController, DictationPhase>(
  DictationController.new,
);
