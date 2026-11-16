import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/l10n/generated/app_localizations.dart';
import 'package:openmosh/shared/ui/atoms/falcon_logo.dart';
import 'package:openmosh/shared/ui/molecules/themed_falcon.dart';

void main() {
  testWidgets('falcon logo paints at the requested size with a screen-reader label', (t) async {
    await t.pumpWidget(const MaterialApp(home: Center(child: FalconLogo(size: 120))));
    expect(t.getSize(find.byType(FalconLogo)), const Size(120, 120));
    expect(find.bySemanticsLabel('Falconer logo'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('decorative falcon is hidden from screen readers', (t) async {
    await t.pumpWidget(const MaterialApp(home: Center(child: FalconLogo(semanticLabel: null))));
    expect(find.bySemanticsLabel('Falconer logo'), findsNothing);
  });

  testWidgets('themed falcon uses the localized label', (t) async {
    await t.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Center(child: ThemedFalcon(size: 80)),
      ),
    );
    expect(find.bySemanticsLabel('Logo de Falconer'), findsOneWidget);
  });

  test('the painter repaints only when the iris color changes', () {
    const a = FalconPainter(iris: Color(0xFF6B93FF));
    const same = FalconPainter(iris: Color(0xFF6B93FF));
    const green = FalconPainter(iris: Color(0xFF4ADE9E));
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(green), isTrue);
  });

  testWidgets('empty-state message shows the falcon, text and actions', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FalconMessage(
            title: 'Nothing here',
            message: 'Details',
            actions: [FilledButton(onPressed: () => taps++, child: const Text('Go'))],
          ),
        ),
      ),
    );
    expect(find.byType(FalconLogo), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    await t.tap(find.text('Go'));
    expect(taps, 1);
  });
}
