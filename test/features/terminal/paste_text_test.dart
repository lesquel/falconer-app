import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/data/datasources/xterm_emulator.dart';
import 'package:openmosh/shared/domain/paste_text.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';

/// The only end-of-paste marker in the output must be the one we add.
void expectOneEnd(String wrapped) {
  expect(wrapped.startsWith('\x1b[200~'), isTrue);
  expect(wrapped.endsWith('\x1b[201~'), isTrue);
  final body = wrapped.substring(6, wrapped.length - 6);
  expect(body.contains('\x1b'), isFalse);
  expect(body.contains('\x9b'), isFalse);
}

void main() {
  test('a nested end marker cannot be rebuilt after filtering', () {
    final out = wrapPaste('\x1b[20\x1b[201~1~; id\n', bracketed: true);
    expectOneEnd(out);
    expect(out, '\x1b[200~[20[201~1~; id\n\x1b[201~');
  });

  test('the 8-bit CSI end marker is removed', () {
    final out = wrapPaste('\x9b201~; id\n', bracketed: true);
    expectOneEnd(out);
    expect(out, '\x1b[200~201~; id\n\x1b[201~');
  });

  test('a doubled ESC cannot rebuild the marker', () {
    final out = wrapPaste('\x1b\x1b[201~[201~', bracketed: true);
    expectOneEnd(out);
  });

  test('tab, line feed and carriage return stay; other C0 and C1 go', () {
    expect(sanitizePaste('a\tb\nc\rd'), 'a\tb\nc\rd');
    expect(sanitizePaste('a\x00b\x07c\x08d\x7fe\x85f\x9fg'), 'abcd\x7fefg');
    expect(sanitizePaste('héllo ñ €'), 'héllo ñ €');
  });

  test('without bracketed paste the text is still sanitized', () {
    expect(wrapPaste('ls\x1b[201~\n', bracketed: false), 'ls[201~\n');
  });

  test('pasted paths are sanitized too', () async {
    final log = <String>[];
    await sendComposed(
      files: const ['/u/a\x1b[201~.jpg'],
      text: '',
      bracketed: true,
      submit: false,
      send: (s) async => log.add(s),
      wait: (_) async {},
    );
    expect(log.first, '\x1b[200~/u/a[201~.jpg\x1b[201~');
  });

  test('a paste through the emulator (Paste shortcut) is sanitized', () async {
    final emu = XtermEmulator();
    final out = <String>[];
    final sub = emu.input.listen(out.add);
    emu.terminal.write('\x1b[?2004h');
    emu.terminal.paste('x\x1b[201~; id\n');
    await Future<void>.delayed(Duration.zero);
    expect(out.single, '\x1b[200~x[201~; id\n\x1b[201~');
    await sub.cancel();
    await emu.dispose();
  });

  test('multi-character keyboard input is sanitized; single keys pass', () async {
    final emu = XtermEmulator();
    final out = <String>[];
    final sub = emu.input.listen(out.add);
    emu.terminal.textInput('a\x1b[201~b');
    emu.terminal.textInput('\x1b');
    await Future<void>.delayed(Duration.zero);
    expect(out, ['a[201~b', '\x1b']);
    await sub.cancel();
    await emu.dispose();
  });

  test("the soft keyboard's Enter (a newline) reaches the terminal as Enter", () async {
    final emu = XtermEmulator();
    final out = <String>[];
    final sub = emu.input.listen(out.add);
    emu.terminal.textInput('\n');
    emu.terminal.textInput('ls\n');
    await Future<void>.delayed(Duration.zero);
    expect(out, ['\r', 'ls\r']);
    await sub.cancel();
    await emu.dispose();
  });
}
