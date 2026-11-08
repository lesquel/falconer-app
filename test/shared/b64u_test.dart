import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/b64u.dart';

void main() {
  test('encodes without padding using the url alphabet', () {
    expect(b64uEncode(Uint8List.fromList([0xfb, 0xff])), '-_8');
    expect(b64uEncode(utf8.encode('a')), 'YQ');
  });

  test('decodes unpadded input', () {
    expect(b64uDecode('-_8'), [0xfb, 0xff]);
    expect(utf8.decode(b64uDecode('YQ')), 'a');
  });

  test('rejects padding and the standard alphabet', () {
    expect(() => b64uDecode('YQ=='), throwsFormatException);
    expect(() => b64uDecode('+/8'), throwsFormatException);
    expect(() => b64uDecode('a'), throwsFormatException);
  });
}
