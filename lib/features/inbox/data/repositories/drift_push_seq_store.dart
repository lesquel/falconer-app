import '../../../../shared/data/app_database.dart';
import '../../domain/repositories/inbox_ports.dart';

/// Stores the highest accepted push seq as a key/value settings row
/// (`push_seq:<device id>`), so no schema change is needed.
class DriftPushSeqStore implements PushSeqStore {
  DriftPushSeqStore(this._db);
  final AppDatabase _db;

  static String _key(String deviceId) => 'push_seq:$deviceId';

  @override
  Future<int> highest(String deviceId) async {
    final row = await (_db.select(
      _db.settingRows,
    )..where((t) => t.key.equals(_key(deviceId)))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }

  /// Never moves backwards.
  @override
  Future<void> record(String deviceId, int seq) async {
    if (seq <= await highest(deviceId)) return;
    await _db
        .into(_db.settingRows)
        .insertOnConflictUpdate(SettingRowsCompanion.insert(key: _key(deviceId), value: '$seq'));
  }
}
