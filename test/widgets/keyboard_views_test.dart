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
}
