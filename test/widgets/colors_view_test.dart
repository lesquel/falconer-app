import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/theme.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/domain/entities/appearance.dart';
import 'package:openmosh/features/settings/presentation/views/colors_view.dart';
import 'package:openmosh/features/settings/presentation/views/settings_view.dart';

Widget app(Widget child, {Brightness brightness = Brightness.dark}) => MaterialApp(
  theme: buildTheme(brightness),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('picking an accent, app theme and terminal scheme reports each choice', (t) async {
    final changes = <AppSettings>[];
    await t.pumpWidget(
      app(ColorsView(settings: const AppSettings(), onChanged: changes.add, onBack: () {})),
    );
    await t.tap(find.byKey(const Key('accent_green')));
    await t.tap(find.byKey(const Key('theme_light')));
    await t.ensureVisible(find.byKey(const Key('scheme_sepia')));
    await t.tap(find.byKey(const Key('scheme_sepia')));
    expect(changes.map((s) => s.accent), [AccentColor.green, AccentColor.blue, AccentColor.blue]);
    expect(changes[1].themePreference, ThemePreference.light);
    expect(changes[2].terminalScheme, TerminalScheme.sepia);
  });

  testWidgets('the selected choices are marked with a check, not only a color', (t) async {
    await t.pumpWidget(
      app(
        ColorsView(
          settings: const AppSettings().copyWith(
            accent: AccentColor.violet,
            themePreference: ThemePreference.dark,
            terminalScheme: TerminalScheme.paper,
          ),
          onChanged: (_) {},
          onBack: () {},
        ),
        brightness: Brightness.light,
      ),
    );
    for (final key in ['accent_violet', 'theme_dark', 'scheme_paper']) {
      expect(
        find.descendant(of: find.byKey(Key(key)), matching: find.byIcon(Icons.check)),
        findsOneWidget,
        reason: key,
      );
    }
    expect(
      find.descendant(of: find.byKey(const Key('accent_blue')), matching: find.byIcon(Icons.check)),
      findsNothing,
    );
    expect(t.getSemantics(find.byKey(const Key('accent_violet'))).label, contains('Violet'));
  });

  testWidgets('every choice is at least 48 px tall and the back button works', (t) async {
    var backs = 0;
    await t.pumpWidget(
      app(ColorsView(settings: const AppSettings(), onChanged: (_) {}, onBack: () => backs++)),
    );
    for (final key in ['accent_blue', 'theme_system', 'scheme_black']) {
      expect(t.getSize(find.byKey(Key(key))).height, greaterThanOrEqualTo(48), reason: key);
    }
    await t.tap(find.byTooltip('Back'));
    expect(backs, 1);
  });

  testWidgets('settings open the Colors screen', (t) async {
    var opened = 0;
    await t.pumpWidget(
      app(
        SettingsView(
          settings: const AppSettings(),
          onChanged: (_) {},
          onAppLockChanged: (_) {},
          onOpenColors: () => opened++,
        ),
      ),
    );
    expect(find.textContaining('Blue accent'), findsOneWidget);
    await t.tap(find.byKey(const Key('open_colors')));
    expect(opened, 1);
  });
}
