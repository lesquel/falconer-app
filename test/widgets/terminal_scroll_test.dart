import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

void main() {
  testWidgets('a scroll gesture sends wheel events at the cell under the finger', (t) async {
    final terminal = Terminal();
    final out = <String>[];
    terminal.onOutput = out.add;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 200),
              Expanded(
                child: TerminalView(
                  terminal,
                  textStyle: const TerminalStyle(fontSize: 10, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Alternate screen with SGR mouse reporting, like Herdr or tmux.
    terminal.write('\x1b[?1049h\x1b[?1000h\x1b[?1006h');
    await t.pump();
    out.clear();

    final view = t.getTopLeft(find.byType(TerminalView));
    await t.dragFrom(view + const Offset(5, 5), const Offset(0, 60));
    await t.pump();

    final wheel = out.where((s) => RegExp(r'^\x1b\[<6\d;').hasMatch(s)).toList();
    expect(wheel, isNotEmpty);
    // Plain wheel (64 up / 65 down), never 68/69 (Shift+wheel).
    expect(wheel.every((s) => s.startsWith('\x1b[<64;') || s.startsWith('\x1b[<65;')), isTrue);
    // The finger started on the first row; global coordinates would put it ~200 px lower.
    final row = int.parse(RegExp(r';(\d+)[Mm]$').firstMatch(wheel.first)!.group(1)!);
    expect(row, lessThanOrEqualTo(2));
  });

  test('wheel and legacy mouse reports use the standard encoding', () {
    final terminal = Terminal();
    final out = <String>[];
    terminal.onOutput = out.add;
    terminal.write('\x1b[?1000h\x1b[?1006h');
    terminal.mouseInput(
      TerminalMouseButton.wheelDown,
      TerminalMouseButtonState.down,
      const CellOffset(4, 2),
    );
    expect(out.last, '\x1b[<65;5;3M');
    terminal.write('\x1b[?1006l');
    terminal.mouseInput(
      TerminalMouseButton.left,
      TerminalMouseButtonState.down,
      const CellOffset(4, 2),
    );
    expect(out.last, '\x1b[M ${String.fromCharCode(32 + 5)}${String.fromCharCode(32 + 3)}');
  });

  testWidgets('changing the font size does not turn the next scroll into a burst', (t) async {
    final terminal = Terminal();
    final out = <String>[];
    terminal.onOutput = out.add;
    Widget app(double size) => MaterialApp(
      home: Scaffold(
        body: TerminalView(
          terminal,
          textStyle: TerminalStyle(fontSize: size, fontFamily: 'monospace'),
        ),
      ),
    );
    await t.pumpWidget(app(10));
    terminal.write('\x1b[?1049h\x1b[?1000h\x1b[?1006h');
    await t.pump();
    final view = t.getTopLeft(find.byType(TerminalView));
    await t.dragFrom(view + const Offset(5, 5), const Offset(0, -120));
    await t.pump();

    await t.pumpWidget(app(24));
    await t.pump();
    out.clear();
    final g = await t.startGesture(view + const Offset(5, 100));
    for (var i = 0; i < 8; i++) {
      await g.moveBy(const Offset(0, -10));
      await t.pump();
    }
    await g.up();
    await t.pump();

    final wheel = out.where((s) => RegExp(r'^\x1b\[<6\d;').hasMatch(s)).toList();
    expect(wheel, isNotEmpty);
    expect(wheel.map((s) => s.substring(0, 6)).toSet(), hasLength(1), reason: 'one direction only');
    expect(wheel.length, lessThanOrEqualTo(4));
  });

  testWidgets('a tap does not open the keyboard when showKeyboardOnTap is false', (t) async {
    final terminal = Terminal();
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TerminalView(terminal, focusNode: focus, showKeyboardOnTap: false)),
      ),
    );
    await t.tap(find.byType(TerminalView));
    await t.pump(const Duration(milliseconds: 500));
    expect(focus.hasFocus, isFalse);
    expect(t.testTextInput.isVisible, isFalse);
  });
}
