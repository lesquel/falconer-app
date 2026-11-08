import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/data/repositories/drift_settings_repository.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/domain/entities/appearance.dart';
import 'package:openmosh/shared/data/app_database.dart';

void main() {
  late AppDatabase db;
  late DriftSettingsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftSettingsRepository(db);
  });
  tearDown(() => db.close());

  Future<void> putRow(String key, String value) => db
      .into(db.settingRows)
      .insertOnConflictUpdate(SettingRowsCompanion(key: Value(key), value: Value(value)));

  test(
    'a fresh install follows the system theme with the blue accent and black terminal',
    () async {
      final s = await repo.load();
      expect(s.themePreference, ThemePreference.system);
      expect(s.accent, AccentColor.blue);
      expect(s.terminalScheme, TerminalScheme.black);
    },
  );

  test('a stored dark=false row from an older version migrates to the light theme', () async {
    await putRow('dark', 'false');
    expect((await repo.load()).themePreference, ThemePreference.light);
  });

  test('a stored dark=true row from an older version migrates to the dark theme', () async {
    await putRow('dark', 'true');
    expect((await repo.load()).themePreference, ThemePreference.dark);
  });

  test('the new theme key wins over the legacy dark key', () async {
    await putRow('dark', 'true');
    await putRow('theme', 'system');
    expect((await repo.load()).themePreference, ThemePreference.system);
  });

  test('unknown stored values fall back to defaults', () async {
    await putRow('theme', 'neon');
    await putRow('accent', 'pink');
    await putRow('terminal_scheme', 'matrix');
    final s = await repo.load();
    expect(s.themePreference, ThemePreference.system);
    expect(s.accent, AccentColor.blue);
    expect(s.terminalScheme, TerminalScheme.black);
  });

  test('appearance choices round-trip and keep the legacy dark key for older builds', () async {
    await repo.save(
      const AppSettings().copyWith(
        themePreference: ThemePreference.light,
        accent: AccentColor.amber,
        terminalScheme: TerminalScheme.sepia,
      ),
    );
    final s = await repo.load();
    expect(s.themePreference, ThemePreference.light);
    expect(s.accent, AccentColor.amber);
    expect(s.terminalScheme, TerminalScheme.sepia);
    final rows = {for (final r in await db.select(db.settingRows).get()) r.key: r.value};
    expect(rows['dark'], 'false');
  });

  test('existing settings still round-trip', () async {
    await repo.save(const AppSettings().copyWith(notificationPreviews: true, fontSize: 18));
    final s = await repo.load();
    expect(s.notificationPreviews, isTrue);
    expect(s.fontSize, 18);
    expect(s.keepConnected, isTrue);
  });
}
