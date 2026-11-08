import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Structural guard (no JVM test runner in this project): FLAG_SECURE is set
// for the whole app before the first frame and nothing may clear it.
void main() {
  final activity = File('android/app/src/main/kotlin/dev/openmosh/openmosh/MainActivity.kt');

  test('MainActivity sets FLAG_SECURE before super.onCreate', () {
    final src = activity.readAsStringSync();
    final flag = src.indexOf('FLAG_SECURE');
    final superCreate = src.indexOf('super.onCreate(');
    expect(flag, isNonNegative);
    expect(superCreate, greaterThan(flag));
  });

  test('no Kotlin or Dart code clears FLAG_SECURE or toggles it per screen', () {
    final files = [
      ...Directory('android/app/src').listSync(recursive: true),
      ...Directory('lib').listSync(recursive: true),
    ].whereType<File>().where((f) => f.path.endsWith('.kt') || f.path.endsWith('.dart'));
    for (final f in files) {
      final src = f.readAsStringSync();
      expect(src.contains('clearFlags'), isFalse, reason: f.path);
      expect(src.contains('secure_window'), isFalse, reason: f.path);
    }
  });
}
