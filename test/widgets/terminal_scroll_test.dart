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

    final wheel = out.where((s) => RegExp(r'^\x1b\[<6\d;').hasMatch(s));
    expect(wheel, isNotEmpty);
    // The finger started on the first row; global coordinates would put it ~200 px lower.
    final row = int.parse(RegExp(r';(\d+)[Mm]$').firstMatch(wheel.first)!.group(1)!);
    expect(row, lessThanOrEqualTo(2));
  });
}
