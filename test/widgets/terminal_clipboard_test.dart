import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/data/datasources/xterm_emulator.dart';
import 'package:openmosh/features/terminal/domain/usecases/terminal_runner.dart';
import 'package:openmosh/features/terminal/presentation/views/terminal_screen_view.dart';
import 'package:xterm/xterm.dart';

/// Hardware-keyboard copy and paste on the terminal (Ctrl+Shift+C, Ctrl+V).
void main() {
  late List<MethodCall> clipboardWrites;
  late String clipboardText;

  setUp(() {
    clipboardWrites = [];
    clipboardText = '';
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.getData') return {'text': clipboardText};
        if (call.method == 'Clipboard.setData') clipboardWrites.add(call);
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Future<FocusNode> pumpTerminal(
    WidgetTester t,
    Terminal terminal, {
    TerminalController? controller,
    VoidCallback? onCopySelection,
  }) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TerminalScreenView(
            terminal: terminal,
            controller: controller,
            phase: TerminalPhase.connected,
            fontSize: 14,
            focusNode: focus,
            keysBar: const SizedBox.shrink(),
            onCopySelection: onCopySelection,
          ),
        ),
      ),
    );
    focus.requestFocus();
    await t.pump();
    return focus;
  }

  testWidgets('a keyboard paste cannot end bracketed paste or inject controls', (t) async {
    final emulator = XtermEmulator();
    addTearDown(emulator.dispose);
    final out = StringBuffer();
    final sub = emulator.input.listen(out.write);
    addTearDown(sub.cancel);
    // The remote app turned bracketed paste on.
    emulator.terminal.write('\x1b[?2004h');
    clipboardText = 'ls\x1b[201~; rm -rf ~\x07\n';

    await pumpTerminal(t, emulator.terminal);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyV);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();

    expect(out.toString(), '\x1b[200~ls[201~; rm -rf ~\n\x1b[201~');
  });

  testWidgets('a keyboard copy goes through the sensitive copy, not the plain clipboard', (
    t,
  ) async {
    final terminal = Terminal()..write('secret-token');
    final controller = TerminalController();
    addTearDown(controller.dispose);
    controller.setSelection(
      terminal.buffer.createAnchor(0, 0),
      terminal.buffer.createAnchor(12, 0),
    );
    var copies = 0;

    await pumpTerminal(t, terminal, controller: controller, onCopySelection: () => copies++);
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyC);
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();

    expect(copies, 1);
    expect(clipboardWrites, isEmpty);
  });
}
