import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/ui/atoms/mole_logo.dart';
import 'package:openmosh/shared/ui/molecules/themed_mole.dart';

void main() {
  testWidgets('mole logo paints at the requested size with a screen-reader label', (t) async {
    await t.pumpWidget(const MaterialApp(home: Center(child: MoleLogo(size: 120))));
    expect(t.getSize(find.byType(MoleLogo)), const Size(120, 120));
    expect(find.bySemanticsLabel('OpenMosh mole'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('decorative mole is hidden from screen readers', (t) async {
    await t.pumpWidget(const MaterialApp(home: Center(child: MoleLogo(semanticLabel: null))));
    expect(find.bySemanticsLabel('OpenMosh mole'), findsNothing);
  });

  test('the painter repaints only when its colors change', () {
    const a = MolePainter(
      goggles: Color(0xFF6B93FF),
      ground: Color(0xFF262626),
      bubble: Color(0xFFFAFAFA),
      bubbleInk: Color(0xFF1F4FD8),
      showBubble: true,
    );
    const same = MolePainter(
      goggles: Color(0xFF6B93FF),
      ground: Color(0xFF262626),
      bubble: Color(0xFFFAFAFA),
      bubbleInk: Color(0xFF1F4FD8),
      showBubble: true,
    );
    const green = MolePainter(
      goggles: Color(0xFF4ADE9E),
      ground: Color(0xFF262626),
      bubble: Color(0xFFFAFAFA),
      bubbleInk: Color(0xFF1F4FD8),
      showBubble: true,
    );
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(green), isTrue);
  });

  testWidgets('empty-state message shows the mole, text and actions', (t) async {
    var taps = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoleMessage(
            title: 'Nothing here',
            message: 'Details',
            actions: [FilledButton(onPressed: () => taps++, child: const Text('Go'))],
          ),
        ),
      ),
    );
    expect(find.byType(MoleLogo), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    await t.tap(find.text('Go'));
    expect(taps, 1);
  });
}
