import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/display_text.dart';

void main() {
  test('sanitizeText strips bidi, zero-width, separators and C1 controls', () {
    expect(
      sanitizeText('run\u202Etxt.exe\u200B\u2028ok\u0085\u009b\x1b[31m', max: 100),
      'runtxt.exeok[31m',
    );
  });

  test('sanitizeText keeps line feeds only when multiline', () {
    expect(sanitizeText('a\r\nb\nc', max: 10, multiline: true), 'a\nb\nc');
    expect(sanitizeText('a\nb', max: 10), 'ab');
  });

  test('cut text ends in an ellipsis and never splits a surrogate pair', () {
    expect(sanitizeText('abcdef', max: 4), 'abc…');
    expect(sanitizeText('abcd', max: 4), 'abcd');
    expect(truncateText('😀😀😀', 2), '😀…');
  });

  test('wire ids accept b64u only', () {
    expect(isWireId('aZ09_-'), isTrue);
    expect(isWireId('../x'), isFalse);
    expect(isWireId('a/b'), isFalse);
    expect(isWireId(''), isFalse);
    expect(isWireId('a' * 129), isFalse);
    expect(isWireId('a' * 65, max: 64), isFalse);
    expect(isWireId(7), isFalse);
  });
}
