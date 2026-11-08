import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/posix_shell.dart';

void main() {
  group('shQuote', () {
    test('wraps plain words in single quotes', () {
      expect(shQuote('list'), "'list'");
    });

    test('empty argument stays an argument', () {
      expect(shQuote(''), "''");
    });

    test('embedded single quotes are closed, escaped and reopened', () {
      expect(shQuote("it's"), "'it'\\''s'");
    });

    test(r'$, backticks, ; and | are inert inside single quotes', () {
      expect(shQuote(r'$(rm -rf ~) `id`; ls | cat'), r"'$(rm -rf ~) `id`; ls | cat'");
    });

    test('newlines are preserved literally', () {
      expect(shQuote('a\nb'), "'a\nb'");
    });

    test('NUL bytes are rejected', () {
      expect(() => shQuote('a\u0000b'), throwsArgumentError);
    });
  });

  test('shJoin quotes every argument including the program', () {
    expect(
      shJoin(['/home/u/.local/bin/openmosh-hook', 'respond', "e'1", '--text', r'$HOME']),
      "'/home/u/.local/bin/openmosh-hook' 'respond' 'e'\\''1' '--text' '\$HOME'",
    );
  });
}
