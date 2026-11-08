import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keyboard/domain/entities/extra_key.dart';
import 'package:openmosh/features/keyboard/domain/entities/key_presets.dart';
import 'package:openmosh/features/keyboard/domain/entities/modifier_state.dart';
import 'package:openmosh/features/keyboard/presentation/views/extra_keys_bar.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('extra keys send sequences and toggle modifiers', (t) async {
    final sent = <String>[];
    final mods = <Modifier>[];
    await t.pumpWidget(
      app(
        ExtraKeysBar(
          base: KeyPresets.base,
          preset: KeyPresets.forName(PresetName.tmux),
          modifiers: const ModifierState(ctrl: true),
          onKey: sent.add,
          onModifier: mods.add,
          onModifierLock: (_) {},
        ),
      ),
    );
    await t.tap(find.text('Esc'));
    await t.tap(find.text('Tab'));
    await t.tap(find.text('Ctrl'));
    await t.tap(find.text('new'));
    expect(sent, ['\x1b', '\t', '\x02c']);
    expect(mods, [Modifier.ctrl]);
  });

  testWidgets('pinned controls sit in the key grid next to Esc', (t) async {
    var taps = 0;
    await t.pumpWidget(
      app(
        ExtraKeysBar(
          base: KeyPresets.base,
          preset: const [],
          modifiers: const ModifierState(),
          onKey: (_) {},
          onModifier: (_) {},
          onModifierLock: (_) {},
          expanded: false,
          onToggleExpanded: () {},
          pinned: [IconButton(icon: const Icon(Icons.keyboard), onPressed: () => taps++)],
        ),
      ),
    );
    final pinned = t.getCenter(find.byIcon(Icons.keyboard));
    final esc = t.getCenter(find.text('Esc'));
    expect(pinned.dy, closeTo(esc.dy, 1));
    expect(pinned.dx, greaterThan(esc.dx));
    await t.tap(find.byIcon(Icons.keyboard));
    expect(taps, 1);
  });

  testWidgets('more keys toggle shows the arrows and the preset row', (t) async {
    var toggles = 0;
    Widget bar(bool expanded) => app(
      ExtraKeysBar(
        base: KeyPresets.base,
        preset: KeyPresets.forName(PresetName.tmux),
        modifiers: const ModifierState(),
        onKey: (_) {},
        onModifier: (_) {},
        onModifierLock: (_) {},
        expanded: expanded,
        onToggleExpanded: () => toggles++,
      ),
    );
    await t.pumpWidget(bar(false));
    expect(find.text('Esc'), findsOneWidget);
    expect(find.text('Alt'), findsNothing);
    expect(find.text('new'), findsNothing);
    await t.tap(find.byTooltip('More keys'));
    expect(toggles, 1);
    await t.pumpWidget(bar(true));
    expect(find.text('Alt'), findsOneWidget);
    expect(find.text('new'), findsOneWidget);
    expect(find.byTooltip('Fewer keys'), findsOneWidget);
  });

  testWidgets('an active modifier shows a marker, not only a color', (t) async {
    await t.pumpWidget(
      app(
        ExtraKeysBar(
          base: KeyPresets.base,
          preset: const [],
          modifiers: const ModifierState(ctrl: true, ctrlLocked: true),
          onKey: (_) {},
          onModifier: (_) {},
          onModifierLock: (_) {},
        ),
      ),
    );
    expect(find.byIcon(Icons.lock), findsOneWidget);
  });

  testWidgets('grid keys are at least 48 px tall', (t) async {
    await t.pumpWidget(
      app(
        ExtraKeysBar(
          base: KeyPresets.base,
          preset: const [],
          modifiers: const ModifierState(),
          onKey: (_) {},
          onModifier: (_) {},
          onModifierLock: (_) {},
        ),
      ),
    );
    expect(t.getSize(find.widgetWithText(InkWell, 'Esc')).height, greaterThanOrEqualTo(48));
  });
}
