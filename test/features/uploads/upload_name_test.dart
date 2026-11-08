import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/uploads/domain/entities/upload_name.dart';
import 'package:openmosh/shared/domain/failure.dart';

void main() {
  String name(String original) => sanitizeUploadName(original, prefix: 'a1b2c3d4');

  test('keeps safe names and adds the random prefix', () {
    expect(name('screenshot_01.png'), 'a1b2c3d4-screenshot_01.png');
  });

  test('replaces unsafe characters and drops path components', () {
    expect(name('../../etc/pass wd'), 'a1b2c3d4-pass_wd');
    expect(name(r'C:\Users\me\My Photo (1).JPG'), 'a1b2c3d4-My_Photo_1_.jpg');
    expect(name('rm -rf \$(id);`x`.txt'), 'a1b2c3d4-rm_-rf_id_x_.txt');
    expect(name('ñandú.png'), 'a1b2c3d4-and_.png');
  });

  test('hidden or empty names get a neutral base', () {
    expect(name('.bashrc'), 'a1b2c3d4-bashrc');
    expect(name(''), 'a1b2c3d4-file');
    expect(name('...'), 'a1b2c3d4-file');
  });

  test('result only contains the allowed alphabet and is bounded', () {
    final n = name('${'x' * 300}.${'e' * 40}');
    expect(RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(n), isTrue);
    expect(n.length, lessThanOrEqualTo(100));
  });

  test('random prefixes differ', () {
    expect(randomUploadPrefix(), isNot(randomUploadPrefix()));
    expect(RegExp(r'^[0-9a-f]{8}$').hasMatch(randomUploadPrefix()), isTrue);
  });

  test('size limit is 50 MB inclusive', () {
    expect(() => checkUploadSize(50 * 1024 * 1024), returnsNormally);
    expect(() => checkUploadSize(50 * 1024 * 1024 + 1), throwsA(isA<ValidationFailure>()));
    expect(() => checkUploadSize(-1), throwsA(isA<ValidationFailure>()));
  });
}
