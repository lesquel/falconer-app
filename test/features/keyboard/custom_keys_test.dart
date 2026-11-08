import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keyboard/domain/entities/custom_keys.dart';
import 'package:openmosh/features/keyboard/domain/entities/key_presets.dart';

void main() {
  test('Ctrl shortcuts map a letter to its control byte', () {
    final c = CustomKeys.ctrl('c')!;
    expect(c.label, 'Ctrl+C');
    expect(c.sequence, '\x03');
    expect(CustomKeys.ctrl('v')!.sequence, '\x16');
    expect(CustomKeys.ctrl('1'), isNull);
    expect(CustomKeys.ctrl('ab'), isNull);
  });

  test('text shortcuts keep the text and can press Enter', () {
    final k = CustomKeys.text('git status', enter: true)!;
    expect(k.label, 'git status');
    expect(k.sequence, 'git status\r');
    expect(CustomKeys.text('a very long command here')!.label, 'a very long…');
    expect(CustomKeys.text('ls', label: 'list')!.label, 'list');
    expect(CustomKeys.text(''), isNull);
  });

  test('Herdr and tmux sessions use their own preset, a shell the chosen one', () {
    expect(KeyPresets.forSession('herdr', PresetName.tmux), PresetName.herdr);
    expect(KeyPresets.forSession('tmux', PresetName.herdr), PresetName.tmux);
    expect(KeyPresets.forSession(null, PresetName.none), PresetName.none);
  });

  test('a text shortcut drops escape and control characters pasted into it', () {
    final k = CustomKeys.text('ls\x1b[201~\x9b; id', enter: true)!;
    expect(k.sequence, 'ls[201~; id\r');
  });

  test('a text shortcut made only of control characters is rejected', () {
    expect(CustomKeys.text('\x1b\x07'), isNull);
  });
}
