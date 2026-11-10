import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/voice/domain/entities/voice_model.dart';
import 'package:openmosh/features/voice/domain/repositories/voice_ports.dart';
import 'package:openmosh/shared/data/app_database.dart';

class FakeModelStore implements ModelStore {
  FakeModelStore([Set<String>? ids, this.offline = false]) : ids = ids ?? {};
  final Set<String> ids;

  /// Airplane mode: any download attempt throws.
  final bool offline;
  final downloads = <String>[];

  /// Ids an earlier run left with the system downloader.
  final interruptedIds = <String>{};
  final resumed = <String>[];

  @override
  Future<Set<String>> installed() async => {...ids};

  @override
  Future<Set<String>> interrupted(Set<String> known) async => interruptedIds.intersection(known);

  @override
  Future<VoiceModel> download(
    VoiceModel model, {
    required DownloadProgress onProgress,
    required DownloadCancel cancel,
    bool resumeOnly = false,
  }) async {
    if (offline) throw StateError('network used in airplane mode');
    if (resumeOnly) {
      resumed.add(model.id);
    } else {
      downloads.add(model.id);
    }
    ids.add(model.id);
    return model;
  }

  @override
  Future<void> delete(String id) async => ids.remove(id);

  @override
  Future<String> folderOf(String id) async => '/models/$id';
}

class FakeRecorder implements VoiceRecorder {
  final calls = <String>[];
  bool grant = true;

  @override
  Future<bool> requestPermission() async {
    calls.add('permission');
    return grant;
  }

  @override
  Future<void> start() async => calls.add('start');

  @override
  Future<Float32List> stop() async {
    calls.add('stop');
    return Float32List(1600);
  }

  @override
  Future<void> cancel() async => calls.add('cancel');
}

class FakeRecognizer implements SpeechRecognizer {
  FakeRecognizer([this.text = 'hola mundo']);
  final String text;
  final requests = <(String, String)>[];

  @override
  Future<String> transcribe(
    Float32List samples, {
    required VoiceModel model,
    required String folder,
    required String language,
  }) async {
    requests.add((model.id, language));
    return text;
  }

  @override
  Future<void> release() async {}
}

/// Real settings persistence on an in-memory database, fake voice adapters.
({ProviderContainer container, AppDatabase db}) voiceContainer({
  required FakeModelStore store,
  FakeRecorder? recorder,
  FakeRecognizer? recognizer,
}) {
  final db = AppDatabase(NativeDatabase.memory());
  final container = ProviderContainer(overrides: voiceOverrides(db, store, recorder, recognizer));
  return (container: container, db: db);
}

List<Override> voiceOverrides(
  AppDatabase db,
  FakeModelStore store, [
  FakeRecorder? recorder,
  FakeRecognizer? recognizer,
]) => [
  databaseProvider.overrideWithValue(db),
  modelStoreProvider.overrideWithValue(store),
  voiceRecorderProvider.overrideWithValue(recorder ?? FakeRecorder()),
  speechRecognizerProvider.overrideWithValue(recognizer ?? FakeRecognizer()),
];
