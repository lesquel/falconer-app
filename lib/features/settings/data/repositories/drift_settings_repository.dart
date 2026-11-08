import 'dart:convert';

import '../../../../shared/data/app_database.dart';
import '../../../keyboard/domain/entities/extra_key.dart';
import '../../../keyboard/domain/entities/key_presets.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/appearance.dart';
import '../../domain/repositories/settings_repository.dart';

/// Settings are key/value rows. Unknown or missing values fall back to defaults.
class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);
  final AppDatabase _db;

  static T? _byName<T extends Enum>(List<T> values, String? name) =>
      values.where((v) => v.name == name).firstOrNull;

  /// `theme` replaced the boolean `dark` key; rows written by older versions
  /// keep their choice.
  static ThemePreference _theme(Map<String, String> m) =>
      _byName(ThemePreference.values, m['theme']) ??
      switch (m['dark']) {
        'true' => ThemePreference.dark,
        'false' => ThemePreference.light,
        _ => const AppSettings().themePreference,
      };

  /// `[[label, bytes], ...]`; anything malformed falls back to the defaults.
  static List<ExtraKey>? _keys(String? raw) {
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          if (e case [final String label, final String seq]) ExtraKey.send(label, seq),
      ];
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  AppSettings _parse(List<SettingRow> rows) {
    final m = {for (final r in rows) r.key: r.value};
    const d = AppSettings();
    return AppSettings(
      notificationPreviews: m['previews'] == 'true',
      themePreference: _theme(m),
      accent: _byName(AccentColor.values, m['accent']) ?? d.accent,
      terminalScheme: _byName(TerminalScheme.values, m['terminal_scheme']) ?? d.terminalScheme,
      fontSize: double.tryParse(m['font'] ?? '') ?? d.fontSize,
      keyPreset: _byName(PresetName.values, m['preset']) ?? d.keyPreset,
      herdrPrefix: m['herdr_prefix'] ?? d.herdrPrefix,
      keepConnected: m['keep_connected'] != 'false',
      appLock: m['app_lock'] == 'true',
      language: _byName(AppLanguage.values, m['language']) ?? d.language,
      customKeys: _keys(m['custom_keys']) ?? d.customKeys,
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
      SettingRowsCompanion.insert(key: 'theme', value: s.themePreference.name),
      // Kept so an older build installed over this one still reads a theme.
      SettingRowsCompanion.insert(
        key: 'dark',
        value: '${s.themePreference != ThemePreference.light}',
      ),
      SettingRowsCompanion.insert(key: 'accent', value: s.accent.name),
      SettingRowsCompanion.insert(key: 'terminal_scheme', value: s.terminalScheme.name),
      SettingRowsCompanion.insert(key: 'font', value: '${s.fontSize}'),
      SettingRowsCompanion.insert(key: 'preset', value: s.keyPreset.name),
      SettingRowsCompanion.insert(key: 'herdr_prefix', value: s.herdrPrefix),
      SettingRowsCompanion.insert(key: 'keep_connected', value: '${s.keepConnected}'),
      SettingRowsCompanion.insert(key: 'app_lock', value: '${s.appLock}'),
      SettingRowsCompanion.insert(key: 'language', value: s.language.name),
      SettingRowsCompanion.insert(
        key: 'custom_keys',
        value: jsonEncode([
          for (final k in s.customKeys)
            if (k.sequence != null) [k.label, k.sequence],
        ]),
      ),
    ]),
  );
}
