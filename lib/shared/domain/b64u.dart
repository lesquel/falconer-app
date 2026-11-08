/// base64url without padding, as used by the OpenMosh wire contract.
library;

import 'dart:convert';
import 'dart:typed_data';

final _valid = RegExp(r'^[A-Za-z0-9_-]*$');

String b64uEncode(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

/// Strict decoder: rejects padding, the standard alphabet and bad lengths.
Uint8List b64uDecode(String input) {
  if (!_valid.hasMatch(input) || input.length % 4 == 1) {
    throw const FormatException('invalid base64url');
  }
  final padded = input.padRight((input.length + 3) ~/ 4 * 4, '=');
  return base64Url.decode(padded);
}
