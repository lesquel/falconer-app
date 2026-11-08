/// xterm package adapter for [TerminalEmulator]. Bytes are decoded as a
/// UTF-8 stream so characters split across batches render correctly.
library;

import 'dart:async';
import 'dart:convert';

import 'package:xterm/xterm.dart';

import '../../../../shared/domain/paste_text.dart';
import '../../domain/repositories/terminal_emulator.dart';

class XtermEmulator implements TerminalEmulator {
  XtermEmulator() : terminal = _SafeTerminal(maxLines: 10000) {
    _sink = const Utf8Decoder(allowMalformed: true)
        .startChunkedConversion(_StringSink(terminal.write));
    terminal.onOutput = _input.add;
    terminal.onResize = (w, h, _, _) => _resizes.add((w, h));
  }

  final Terminal terminal;
  late final ByteConversionSink _sink;
  final _input = StreamController<String>.broadcast();
  final _resizes = StreamController<(int, int)>.broadcast();

  /// Text injected by the extra-keys bar goes through the same path as typing.
  void type(String data) => _input.add(data);

  @override
  int get cols => terminal.viewWidth;
  @override
  int get rows => terminal.viewHeight;

  @override
  void feed(List<int> bytes) => _sink.add(bytes);

  @override
  void notice(String text) => terminal.write('\r\n\x1b[2m$text\x1b[0m\r\n');

  /// RIS: full reset (main screen, mouse modes off, cleared).
  @override
  void reset() => terminal.write('\x1bc');

  @override
  Stream<String> get input => _input.stream;
  @override
  Stream<(int, int)> get resizes => _resizes.stream;

  Future<void> dispose() async {
    await _input.close();
    await _resizes.close();
  }
}

class _StringSink implements Sink<String> {
  _StringSink(this._write);
  final void Function(String) _write;
  @override
  void add(String data) => _write(data);
  @override
  void close() {}
}

/// Decorator base so presentation can adjust input without subclassing
/// the adapter.
class XtermProxy implements TerminalEmulator {
  XtermProxy(this.inner);
  final XtermEmulator inner;
  @override
  int get cols => inner.cols;
  @override
  int get rows => inner.rows;
  @override
  void feed(List<int> bytes) => inner.feed(bytes);
  @override
  void notice(String text) => inner.notice(text);
  @override
  void reset() => inner.reset();
  @override
  Stream<String> get input => inner.input;
  @override
  Stream<(int, int)> get resizes => inner.resizes;
}

/// Sanitizes what the terminal view pastes (Paste shortcut) and multi-character
/// keyboard inserts (a soft keyboard pasting from its clipboard), so neither
/// can end bracketed paste early or inject control sequences. A single
/// character passes untouched: keyboards may send ESC or a control key as text.
class _SafeTerminal extends Terminal {
  _SafeTerminal({super.maxLines});

  @override
  void paste(String text) => super.paste(sanitizePaste(text));

  @override
  void textInput(String text) => super.textInput(text.length > 1 ? sanitizePaste(text) : text);
}
