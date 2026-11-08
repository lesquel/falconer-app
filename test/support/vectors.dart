import 'dart:convert';
import 'dart:io';

/// Loads a cross-implementation vector file committed by openmosh-hook
/// (`hook/tests/vectors/`), copied into `test/fixtures/vectors/`.
Map<String, Object?>? loadVector(String name) {
  final f = File('test/fixtures/vectors/$name');
  if (!f.existsSync()) return null;
  return jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
}

/// Vector plaintext fields are JSON text; accept b64u-encoded bytes too.
List<int> textOrBytes(String v, List<int> Function(String) b64u) {
  try {
    jsonDecode(v);
    return utf8.encode(v);
  } on FormatException {
    return b64u(v);
  }
}

const vectorsPending = 'vectors pending';
