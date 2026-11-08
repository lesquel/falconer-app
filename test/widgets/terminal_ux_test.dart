import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keyboard/domain/entities/extra_key.dart';
import 'package:openmosh/features/keyboard/domain/entities/key_presets.dart';
import 'package:openmosh/features/keyboard/domain/entities/modifier_state.dart';
import 'package:openmosh/features/keyboard/presentation/views/extra_keys_bar.dart';
import 'package:openmosh/features/terminal/domain/usecases/terminal_runner.dart';
import 'package:openmosh/features/terminal/presentation/views/shortcut_dialog.dart';
import 'package:openmosh/features/terminal/presentation/views/terminal_screen_view.dart';
import 'package:xterm/xterm.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('saved shortcuts send their bytes and report long presses', (t) async {
    final sent = <String>[];
    final held = <int>[];
    await t.pumpWidget(
      _app(
        Align(
          alignment: Alignment.bottomCenter,
          child: ExtraKeysBar(
            base: KeyPresets.base,
            preset: const [],
            modifiers: const ModifierState(),
            onKey: sent.add,
            onModifier: (_) {},
            onModifierLock: (_) {},
            shortcuts: const [ExtraKey.send('Ctrl+C', '\x03'), ExtraKey.send('Ctrl+V', '\x16')],
            onShortcutLongPress: held.add,
          ),
        ),
      ),
    );
    await t.tap(find.text('Ctrl+C'));
    await t.longPress(find.text('Ctrl+V'));
    expect(sent, ['\x03']);
    expect(held, [1]);
  });

  testWidgets('the shortcut dialog builds a Ctrl shortcut from a letter', (t) async {
    ExtraKey? result;
    await t.pumpWidget(
      _app(
        Builder(
          builder: (c) => TextButton(
            onPressed: () async => result = await showShortcutDialog(c),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('shortcut-value')), 'v');
    await t.pump();
    await t.tap(find.text('Add Ctrl+V'));
    await t.pumpAndSettle();
    expect(result?.sequence, '\x16');
  });

  testWidgets('the terminal does not take focus on its own and reports pinches', (t) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    final scales = <double>[];
    var ended = false;
    await t.pumpWidget(
      _app(
        TerminalScreenView(
          terminal: Terminal(),
          phase: TerminalPhase.connected,
          fontSize: 14,
          focusNode: focus,
          keysBar: const SizedBox.shrink(),
          onPinchUpdate: scales.add,
          onPinchEnd: () => ended = true,
        ),
      ),
    );
    await t.pump();
    expect(focus.hasFocus, isFalse, reason: 'opening a terminal must not open the keyboard');

    final center = t.getCenter(find.byType(TerminalView));
    final a = await t.startGesture(center - const Offset(20, 0));
    final b = await t.startGesture(center + const Offset(20, 0), pointer: 2);
    await a.moveBy(const Offset(-20, 0));
    await b.moveBy(const Offset(20, 0));
    await a.up();
    await b.up();
    await t.pump(const Duration(milliseconds: 500));
    expect(scales.last, closeTo(2, 0.01));
    expect(ended, isTrue);
  });
}
