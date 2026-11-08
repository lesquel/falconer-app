import '../../../../shared/data/app_database.dart';
import '../../../keyboard/domain/entities/key_presets.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);
  final AppDatabase _db;

  AppSettings _parse(List<SettingRow> rows) {
    final m = {for (final r in rows) r.key: r.value};
    const d = AppSettings();
    return AppSettings(
      notificationPreviews: m['previews'] == 'true',
      darkTheme: m['dark'] != 'false',
      fontSize: double.tryParse(m['font'] ?? '') ?? d.fontSize,
      keyPreset: PresetName.values.where((p) => p.name == m['preset']).firstOrNull ?? d.keyPreset,
      herdrPrefix: m['herdr_prefix'] ?? d.herdrPrefix,
    );
  }

  @override
  Future<AppSettings> load() async => _parse(await _db.select(_db.settingRows).get());

  @override
  Stream<AppSettings> watch() => _db.select(_db.settingRows).watch().map(_parse);

  @override
  Future<void> save(AppSettings s) => _db.batch(
    (b) => b.insertAllOnConflictUpdate(_db.settingRows, [
      SettingRowsCompanion.insert(key: 'previews', value: '${s.notificationPreviews}'),
      SettingRowsCompanion.insert(key: 'dark', value: '${s.darkTheme}'),
      SettingRowsCompanion.insert(key: 'font', value: '${s.fontSize}'),
      SettingRowsCompanion.insert(key: 'preset', value: s.keyPreset.name),
      SettingRowsCompanion.insert(key: 'herdr_prefix', value: s.herdrPrefix),
    ]),
  );
}
