import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/repositories/drift_sync_cursor_store.dart';
import 'package:openmosh/features/settings/data/repositories/drift_settings_repository.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/shared/data/app_database.dart';

void main() {
  late AppDatabase db;
  late DriftSyncCursorStore store;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    store = DriftSyncCursorStore(db);
  });
  tearDown(() => db.close());

  test('the sync cursor is persisted per host', () async {
    expect(await store.read('h1'), 0);
    await store.write('h1', 9);
    await store.write('h2', 2);
    expect(await DriftSyncCursorStore(db).read('h1'), 9);
    expect(await DriftSyncCursorStore(db).read('h2'), 2);
  });

  test('cursor rows and legacy push_seq rows do not disturb the settings', () async {
    await store.write('h1', 9);
    await db
        .into(db.settingRows)
        .insertOnConflictUpdate(SettingRowsCompanion.insert(key: 'push_seq:kid1', value: '7'));
    final s = await DriftSettingsRepository(db).load();
    expect(s.keepConnected, const AppSettings().keepConnected);
    expect(await store.read('kid1'), 0);
  });
}
