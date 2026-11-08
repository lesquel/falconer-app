import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/repositories/drift_push_seq_store.dart';
import 'package:openmosh/features/settings/data/repositories/drift_settings_repository.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/shared/data/app_database.dart';

void main() {
  late AppDatabase db;
  late DriftPushSeqStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftPushSeqStore(db);
  });
  tearDown(() => db.close());

  test('the highest seq is persisted per device and never moves backwards', () async {
    expect(await store.highest('kid1'), 0);
    await store.record('kid1', 9);
    await store.record('kid1', 4);
    await store.record('kid2', 2);
    expect(await store.highest('kid1'), 9);
    expect(await DriftPushSeqStore(db).highest('kid2'), 2);
  });

  test('seq rows do not disturb the settings', () async {
    await store.record('kid1', 9);
    final s = await DriftSettingsRepository(db).load();
    expect(s.keepConnected, const AppSettings().keepConnected);
  });
}
