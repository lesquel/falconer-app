import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/presentation/views/settings_view.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('settings: previews are off by default and can be enabled', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(SettingsView(settings: const AppSettings(), onChanged: (s) => changed = s)),
    );
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('previews')));
    expect(sw.value, isFalse);
    await t.tap(find.byKey(const Key('previews')));
    expect(changed!.notificationPreviews, isTrue);
  });

  testWidgets('settings: sessions stay connected by default and can be turned off', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(SettingsView(settings: const AppSettings(), onChanged: (s) => changed = s)),
    );
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('keep_connected')));
    expect(sw.value, isTrue);
    await t.tap(find.byKey(const Key('keep_connected')));
    expect(changed!.keepConnected, isFalse);
  });

  testWidgets('settings: the app lock is off by default and can be turned on', (t) async {
    AppSettings? changed;
    await t.pumpWidget(
      app(SettingsView(settings: const AppSettings(), onChanged: (s) => changed = s)),
    );
    final sw = find.byKey(const Key('app_lock'));
    await t.scrollUntilVisible(sw, 200);
    expect(t.widget<SwitchListTile>(sw).value, isFalse);
    expect(find.text('Lock OpenMosh'), findsOneWidget);
    await t.tap(sw);
    expect(changed!.appLock, isTrue);
  });

  test('font size is clamped to 8..32', () {
    expect(const AppSettings().copyWith(fontSize: 40).fontSize, 32);
    expect(const AppSettings().copyWith(fontSize: 2).fontSize, 8);
  });
}
