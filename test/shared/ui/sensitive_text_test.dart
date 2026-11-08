import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/ui/atoms/sensitive_text.dart';

import '../../support/l10n_app.dart';

void main() {
  Widget page(Widget child, {Locale locale = const Locale('en')}) => l10nApp(
    home: Scaffold(body: child),
    locale: locale,
  );

  testWidgets('starts masked, not selectable, and the eye toggles it', (t) async {
    await t.pumpWidget(page(const SensitiveText('100.1.2.3', masked: '100.••.••.3')));
    expect(find.text('100.••.••.3'), findsOneWidget);
    expect(find.text('100.1.2.3'), findsNothing);
    expect(find.byType(SelectableText), findsNothing);
    final eye = t.getSize(find.byType(IconButton));
    expect(eye.width, greaterThanOrEqualTo(44));
    expect(eye.height, greaterThanOrEqualTo(44));

    await t.tap(find.byTooltip('Show'));
    await t.pump();
    expect(find.text('100.1.2.3'), findsOneWidget);
    await t.tap(find.byTooltip('Hide'));
    await t.pump();
    expect(find.text('100.1.2.3'), findsNothing);
  });

  testWidgets('format wraps the shown value', (t) async {
    await t.pumpWidget(page(SensitiveText('1.2.3.4', masked: 'x', format: (v) => 'Pair with $v')));
    expect(find.text('Pair with x'), findsOneWidget);
  });

  testWidgets('the revealed state resets when the screen is rebuilt from scratch', (t) async {
    await t.pumpWidget(page(const SensitiveText('secret', masked: '••••')));
    await t.tap(find.byTooltip('Show'));
    await t.pump();
    expect(find.text('secret'), findsOneWidget);
    await t.pumpWidget(page(const SizedBox()));
    await t.pumpWidget(page(const SensitiveText('secret', masked: '••••')));
    expect(find.text('secret'), findsNothing);
  });

  testWidgets('tooltips are localized', (t) async {
    await t.pumpWidget(page(const SensitiveText('a', masked: 'b'), locale: const Locale('es')));
    expect(find.byTooltip('Mostrar'), findsOneWidget);
  });
}
