import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/domain/entities/appearance.dart';
import 'package:openmosh/features/settings/presentation/views/settings_view.dart';

import '../support/l10n_app.dart';

Widget app(Widget child, {Locale locale = const Locale('en')}) => l10nApp(
  home: Scaffold(body: child),
  locale: locale,
);

void main() {
  testWidgets('settings: previews are off by default and can be enabled', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(),
          onChanged: (s) => changed = s,
          onAppLockChanged: (_) {},
        ),
      ),
    );
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('previews')));
    expect(sw.value, isFalse);
    await t.tap(find.byKey(const Key('previews')));
    expect(changed!.notificationPreviews, isTrue);
  });

  testWidgets('settings: sessions stay connected by default and can be turned off', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(),
          onChanged: (s) => changed = s,
          onAppLockChanged: (_) {},
        ),
      ),
    );
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('keep_connected')));
    expect(sw.value, isTrue);
    await t.tap(find.byKey(const Key('keep_connected')));
    expect(changed!.keepConnected, isFalse);
  });

  testWidgets('settings: the app lock is off by default; its switch asks to toggle it', (t) async {
    AppSettings? changed;
    bool? toggled;
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(),
          onChanged: (s) => changed = s,
          onAppLockChanged: (v) => toggled = v,
        ),
      ),
    );
    final sw = find.byKey(const Key('app_lock'));
    await t.scrollUntilVisible(sw, 200);
    expect(t.widget<SwitchListTile>(sw).value, isFalse);
    expect(find.text('Lock OpenMosh'), findsOneWidget);
    await t.tap(sw);
    expect(toggled, isTrue);
    expect(changed, isNull, reason: 'the container saves only after verification');
  });

  testWidgets('settings: the language row saves Spanish', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(),
          onChanged: (s) => changed = s,
          onAppLockChanged: (_) {},
        ),
      ),
    );
    final row = find.byKey(const Key('language'));
    await t.scrollUntilVisible(row, 200);
    expect(find.text('Language'), findsOneWidget);
    expect(find.descendant(of: row, matching: find.text('System')), findsOneWidget);
    await t.tap(find.byType(DropdownButton<AppLanguage>));
    await t.pumpAndSettle();
    await t.tap(find.text('Español').last);
    await t.pumpAndSettle();
    expect(changed!.language, AppLanguage.es);
  });

  testWidgets('settings: renders in Spanish under the es locale', (t) async {
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(language: AppLanguage.es),
          onChanged: (_) {},
          onAppLockChanged: (_) {},
        ),
        locale: const Locale('es'),
      ),
    );
    expect(find.text('Ajustes'), findsOneWidget);
    expect(find.text('Vista previa de notificaciones'), findsOneWidget);
    expect(find.text('Mantener las sesiones conectadas'), findsOneWidget);
    expect(find.text('Notification previews'), findsNothing);
    await t.scrollUntilVisible(find.byKey(const Key('language')), 200);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
  });

  test('font size is clamped to 8..32', () {
    expect(const AppSettings().copyWith(fontSize: 40).fontSize, 32);
    expect(const AppSettings().copyWith(fontSize: 2).fontSize, 8);
  });

  testWidgets('settings: the light / dark switch is on the main screen', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(),
          onChanged: (s) => changed = s,
          onAppLockChanged: (_) {},
        ),
      ),
    );
    expect(find.byKey(const Key('theme_switch')), findsOneWidget);
    await t.tap(find.byIcon(Icons.light_mode_outlined));
    await t.pump();
    expect(changed?.themePreference, ThemePreference.light);
  });

  testWidgets('settings: the language picker sits next to the theme, visible without scrolling', (
    t,
  ) async {
    await t.pumpWidget(
      app(SettingsView(settings: const AppSettings(), onChanged: (_) {}, onAppLockChanged: (_) {})),
    );
    expect(find.byKey(const Key('language')).hitTestable(), findsOneWidget);
    expect(find.byType(DropdownButton<AppLanguage>), findsOneWidget, reason: 'no second row');
    final theme = t.getTopLeft(find.byKey(const Key('theme_switch')));
    final lang = t.getTopLeft(find.byKey(const Key('language')));
    expect(lang.dy - theme.dy, lessThan(120));
  });
}
