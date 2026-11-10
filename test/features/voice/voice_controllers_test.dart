import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/voice/domain/entities/voice_catalog.dart';
import 'package:openmosh/features/voice/presentation/controllers/dictation_controller.dart';
import 'package:openmosh/features/voice/presentation/controllers/voice_models_controller.dart';

import 'voice_fakes.dart';

void main() {
  test('opening voice settings never starts a download', () async {
    final store = FakeModelStore();
    final (:container, :db) = voiceContainer(store: store);
    addTearDown(db.close);
    addTearDown(container.dispose);
    container.read(voiceModelsControllerProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(voiceModelsControllerProvider).installed, isEmpty);
    expect(store.downloads, isEmpty);
  });

  test('opening voice settings finishes an interrupted download, never starts one', () async {
    final store = FakeModelStore()..interruptedIds.addAll({'parakeet-tdt-0.6b-v3-int8', 'gone'});
    final (:container, :db) = voiceContainer(store: store);
    addTearDown(db.close);
    addTearDown(container.dispose);
    container.read(voiceModelsControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(store.resumed, ['parakeet-tdt-0.6b-v3-int8']);
    expect(store.downloads, isEmpty);
    expect(container.read(voiceModelsControllerProvider).installed, {'parakeet-tdt-0.6b-v3-int8'});
  });

  test('a download happens only when asked and selects the model when none was', () async {
    final store = FakeModelStore();
    final (:container, :db) = voiceContainer(store: store);
    addTearDown(db.close);
    addTearDown(container.dispose);
    final c = container.read(voiceModelsControllerProvider.notifier);
    expect(await c.download(catalogModel('whisper-base')!), DownloadOutcome.done);
    expect(store.downloads, ['whisper-base']);
    expect((await container.read(settingsRepositoryProvider).load()).voiceModelId, 'whisper-base');
  });

  test('with no model selected the mic asks for setup without recording or permission', () async {
    final recorder = FakeRecorder();
    final (:container, :db) = voiceContainer(store: FakeModelStore(), recorder: recorder);
    addTearDown(db.close);
    addTearDown(container.dispose);
    final outcome = await container.read(dictationControllerProvider.notifier).tap();
    expect(outcome, isA<MicNeedsSetup>());
    expect(recorder.calls, isEmpty);
  });

  test('a selected model that is not downloaded also asks for setup', () async {
    final recorder = FakeRecorder();
    final (:container, :db) = voiceContainer(store: FakeModelStore(), recorder: recorder);
    addTearDown(db.close);
    addTearDown(container.dispose);
    await container
        .read(settingsRepositoryProvider)
        .save(const AppSettings().withVoiceModel('whisper-base'));
    expect(await container.read(dictationControllerProvider.notifier).tap(), isA<MicNeedsSetup>());
    expect(recorder.calls, isEmpty);
  });

  test('dictation works offline: record and transcribe never touch the downloader', () async {
    final store = FakeModelStore({'whisper-base'}, true);
    final recorder = FakeRecorder();
    final recognizer = FakeRecognizer();
    final (:container, :db) = voiceContainer(
      store: store,
      recorder: recorder,
      recognizer: recognizer,
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    await container
        .read(settingsRepositoryProvider)
        .save(const AppSettings(voiceLanguage: 'es').withVoiceModel('whisper-base'));
    final d = container.read(dictationControllerProvider.notifier);
    expect(await d.tap(), isA<MicStarted>());
    expect(container.read(dictationControllerProvider), DictationPhase.recording);
    final text = await d.tap();
    expect((text as MicText).text, 'hola mundo');
    expect(recorder.calls, ['permission', 'start', 'stop']);
    expect(recognizer.requests, [('whisper-base', 'es')]);
    expect(store.downloads, isEmpty);
    expect(container.read(dictationControllerProvider), DictationPhase.idle);
  });

  test('a refused microphone permission does not record', () async {
    final recorder = FakeRecorder()..grant = false;
    final (:container, :db) = voiceContainer(
      store: FakeModelStore({'whisper-base'}),
      recorder: recorder,
    );
    addTearDown(db.close);
    addTearDown(container.dispose);
    await container
        .read(settingsRepositoryProvider)
        .save(const AppSettings().withVoiceModel('whisper-base'));
    expect(
      await container.read(dictationControllerProvider.notifier).tap(),
      isA<MicPermissionDenied>(),
    );
    expect(recorder.calls, ['permission']);
  });
}
