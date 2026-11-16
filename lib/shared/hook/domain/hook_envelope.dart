/// Parser for the hook JSON envelope:
/// `{"ok":true,"data":…}` or `{"ok":false,"error":{"code","message"}}`.
library;

import 'dart:convert';

import '../../domain/failure.dart';

Object? parseHookEnvelope(List<int> stdout) {
  final Object? decoded;
  try {
    decoded = jsonDecode(utf8.decode(stdout, allowMalformed: true));
  } on FormatException {
    throw const HookFailure('protocol', 'falconer-hook returned unexpected output.');
  }
  if (decoded is! Map<String, Object?>) {
    throw const HookFailure('protocol', 'falconer-hook returned unexpected output.');
  }
  if (decoded['ok'] == true) return decoded['data'];
  final err = decoded['error'];
  if (err is Map<String, Object?>) {
    final code = err['code'] is String ? err['code']! as String : 'error';
    final msg = err['message'] is String ? err['message']! as String : 'Host command failed.';
    throw HookFailure(code, msg.length > 200 ? msg.substring(0, 200) : msg);
  }
  throw const HookFailure('protocol', 'falconer-hook returned unexpected output.');
}
