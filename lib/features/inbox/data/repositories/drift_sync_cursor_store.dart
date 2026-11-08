import '../../../../shared/data/app_database.dart';
import '../../domain/repositories/inbox_ports.dart';

/// Stores the sync cursor as a key/value settings row
/// (`sync_cursor:<host id>`), so no schema change is needed. Rows named
/// `push_seq:<device id>` were written by the old push high-water mark; they
/// are no longer read and stay harmless.
class DriftSyncCursorStore implements SyncCursorStore {
  DriftSyncCursorStore(this._db);
  final AppDatabase _db;

  static String _key(String hostId) => 'sync_cursor:$hostId';

  @override
  Future<int> read(String hostId) async {
    final row = await (_db.select(
      _db.settingRows,
    )..where((t) => t.key.equals(_key(hostId)))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }

  @override
  Future<void> write(String hostId, int seq) => _db
      .into(_db.settingRows)
      .insertOnConflictUpdate(SettingRowsCompanion.insert(key: _key(hostId), value: '$seq'));
}
