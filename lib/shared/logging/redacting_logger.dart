/// The only logging entry point in the app (T-7). Every message passes
/// through [redact]; release builds drop everything below warning.
library;

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

final _patterns = <RegExp>[
  RegExp(r'-----BEGIN [A-Z ]+-----[\s\S]*?-----END [A-Z ]+-----'),
  RegExp(r'ssh-ed25519 [A-Za-z0-9+/=]+'),
  RegExp(r'openmosh://\S+'),
  RegExp(r'https?://\S+'),
  // long base64/base64url/hex runs: tokens, keys, nonces, ciphertext
  RegExp(r'[A-Za-z0-9+/_=-]{20,}'),
];

String redact(String input) {
  var out = input;
  for (final p in _patterns) {
    out = out.replaceAll(p, '[redacted]');
  }
  return out;
}

enum LogLevel { debug, info, warning, error }

abstract final class Log {
  static void debug(String tag, String message) => _emit(LogLevel.debug, tag, message);
  static void info(String tag, String message) => _emit(LogLevel.info, tag, message);
  static void warning(String tag, String message) => _emit(LogLevel.warning, tag, message);

  /// Errors are logged by type only; their text may carry remote data.
  static void error(String tag, String message, [Object? error]) =>
      _emit(LogLevel.error, tag, error == null ? message : '$message (${error.runtimeType})');

  static void _emit(LogLevel level, String tag, String message) {
    if (kReleaseMode && level.index < LogLevel.warning.index) return;
    developer.log(redact(message), name: 'openmosh.$tag', level: 500 + level.index * 300);
  }
}
