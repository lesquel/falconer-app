import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keyboard/domain/entities/extra_key.dart';
import 'package:openmosh/features/keyboard/domain/entities/key_presets.dart';
import 'package:openmosh/features/keyboard/domain/entities/modifier_state.dart';
import 'package:openmosh/features/keyboard/presentation/views/extra_keys_bar.dart';
import 'package:openmosh/features/terminal/domain/usecases/terminal_runner.dart';
import 'package:openmosh/features/terminal/presentation/views/chat_composer.dart';
import 'package:openmosh/features/terminal/presentation/views/shortcut_dialog.dart';
import 'package:openmosh/features/terminal/presentation/views/terminal_screen_view.dart';
import 'package:xterm/xterm.dart';

import '../support/l10n_app.dart';

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

  testWidgets('the shortcut dialog renders in Spanish under the es locale', (t) async {
    await t.pumpWidget(
      l10nApp(
        locale: const Locale('es'),
        home: Scaffold(
          body: Builder(
            builder: (c) =>
                TextButton(onPressed: () => showShortcutDialog(c), child: const Text('open')),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
    expect(find.text('Agregar atajo'), findsOneWidget);
    expect(find.text('Ctrl + tecla'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
  });

  testWidgets(
    'on a tablet the arrow cross is always visible, sends arrows and repeats while held',
    (t) async {
      final sent = <String>[];
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
              expanded: true,
              onToggleExpanded: () {},
            ),
          ),
        ),
      );
      expect(find.text('←'), findsNothing, reason: 'arrows left the scrolling rows');
      await t.tap(find.bySemanticsLabel('Up'));
      await t.tap(find.bySemanticsLabel('Left'));
      expect(sent, ['\x1b[A', '\x1b[D']);
      sent.clear();
      final g = await t.startGesture(t.getCenter(find.bySemanticsLabel('Down')));
      await t.pump(const Duration(milliseconds: 600));
      await t.pump(const Duration(milliseconds: 400));
      await g.up();
      await t.pump(const Duration(milliseconds: 300));
      expect(sent.length, greaterThan(2));
      expect(sent.toSet(), {'\x1b[B'});
    },
  );

  testWidgets('chat Paste inserts the phone clipboard into the message', (t) async {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.getData') return {'text': 'npm test'};
      return null;
    });
    addTearDown(
      () =>
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    final changes = <String>[];
    await t.pumpWidget(
      _app(
        Align(
          alignment: Alignment.bottomCenter,
          child: ChatComposer(
            initialText: 'run ',
            attachments: const [],
            onSend: (_) {},
            onChanged: changes.add,
            onAttach: () {},
            onRemoveAttachment: (_) {},
            onClose: () {},
          ),
        ),
      ),
    );
    await t.tap(find.byKey(const Key('chat-paste')));
    await t.pump();
    expect(changes.last, 'run npm test');
  });

  testWidgets('on a phone the bar is one row; arrows appear with more keys', (t) async {
    t.view.physicalSize = const Size(1080, 2340);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    Widget bar(bool expanded) => _app(
      Align(
        alignment: Alignment.bottomCenter,
        child: ExtraKeysBar(
          base: KeyPresets.base,
          preset: const [],
          modifiers: const ModifierState(),
          onKey: (_) {},
          onModifier: (_) {},
          onModifierLock: (_) {},
          expanded: expanded,
          onToggleExpanded: () {},
          pinned: [
            KeyGridButton(tooltip: 'Chat', icon: Icons.chat_bubble_outline, onPressed: () {}),
            KeyGridButton(tooltip: 'Keyboard', icon: Icons.keyboard, onPressed: () {}),
          ],
        ),
      ),
    );
    await t.pumpWidget(bar(false));
    expect(find.byType(ArrowCross), findsNothing);
    final esc = t.getCenter(find.text('Esc'));
    final kb = t.getCenter(find.byIcon(Icons.keyboard));
    expect(kb.dy, closeTo(esc.dy, 1), reason: 'one row of keys');
    await t.pumpWidget(bar(true));
    expect(find.byType(ArrowCross), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a two-finger double tap asks for the keyboard; one tap does not', (t) async {
    var taps = 0;
    await t.pumpWidget(
      _app(
        TerminalScreenView(
          terminal: Terminal(),
          phase: TerminalPhase.connected,
          fontSize: 14,
          keysBar: const SizedBox.shrink(),
          onTwoFingerDoubleTap: () => taps++,
        ),
      ),
    );
    final c = t.getCenter(find.byType(TerminalView));
    Future<void> twoFingerTap() async {
      final a = await t.startGesture(c - const Offset(30, 0));
      final b = await t.startGesture(c + const Offset(30, 0), pointer: 2);
      await t.pump(const Duration(milliseconds: 50));
      await a.up();
      await b.up();
    }

    await twoFingerTap();
    await t.pump(const Duration(milliseconds: 100));
    expect(taps, 0);
    await twoFingerTap();
    await t.pump(const Duration(milliseconds: 500));
    expect(taps, 1);
  });
}
