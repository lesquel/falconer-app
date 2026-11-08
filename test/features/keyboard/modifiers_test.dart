import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keyboard/domain/entities/extra_key.dart';
import 'package:openmosh/features/keyboard/domain/entities/key_presets.dart';
import 'package:openmosh/features/keyboard/domain/entities/modifier_state.dart';

void main() {
  test('ctrl turns the next letter into a control code, then releases', () {
    final m = const ModifierState().toggle(Modifier.ctrl);
    final (out, next) = m.apply('c');
    expect(out, '\x03');
    expect(next.ctrl, isFalse);
    expect(next.apply('c').$1, 'c');
  });

  test('ctrl handles upper case, space, brackets and ?', () {
    final m = const ModifierState(ctrl: true);
    expect(m.apply('A').$1, '\x01');
    expect(m.apply(' ').$1, '\x00');
    expect(m.apply('[').$1, '\x1b');
    expect(m.apply('?').$1, '\x7f');
    expect(m.apply('1').$1, '1');
  });

  test('alt prefixes ESC; ctrl+alt combine', () {
    expect(const ModifierState(alt: true).apply('b').$1, '\x1bb');
    expect(const ModifierState(ctrl: true, alt: true).apply('x').$1, '\x1b\x18');
  });

  test('locked modifiers stay armed', () {
    final m = const ModifierState().toggle(Modifier.ctrl).lock(Modifier.ctrl);
    expect(m.apply('a').$2.ctrl, isTrue);
  });

  test('default bar exposes the required keys with correct bytes', () {
    final keys = {for (final k in KeyPresets.base) k.label: k};
    expect(keys['Esc']!.sequence, '\x1b');
    expect(keys['Tab']!.sequence, '\t');
    expect(keys['↑']!.sequence, '\x1b[A');
    expect(keys['↓']!.sequence, '\x1b[B');
    expect(keys['→']!.sequence, '\x1b[C');
    expect(keys['←']!.sequence, '\x1b[D');
    for (final s in ['|', '/', '~', '-']) {
      expect(keys[s]!.sequence, s);
    }
    expect(keys['Ctrl']!.modifier, Modifier.ctrl);
    expect(keys['Alt']!.modifier, Modifier.alt);
  });

  test('tmux and Herdr presets send their prefix', () {
    final tmux = KeyPresets.forName(PresetName.tmux);
    expect(tmux.firstWhere((k) => k.label == 'new').sequence, '\x02c');
    final herdr = KeyPresets.forName(PresetName.herdr, herdrPrefix: '\x01');
    expect(herdr.every((k) => k.sequence!.startsWith('\x01')), isTrue);
    expect(KeyPresets.forName(PresetName.none), isEmpty);
  });
}
