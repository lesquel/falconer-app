import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/presentation/views/settings_view.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('settings: previews are off by default and can be enabled', (t) async {
    AppSettings? changed;
    await t.pumpWidget(app(SettingsView(settings: const AppSettings(), onChanged: (s) => changed = s)));
    final sw = t.widget<SwitchListTile>(find.byKey(const Key('previews')));
    expect(sw.value, isFalse);
    await t.tap(find.byKey(const Key('previews')));
    expect(changed!.notificationPreviews, isTrue);
  });
}
