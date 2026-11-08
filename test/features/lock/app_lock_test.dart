import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/lock/domain/app_lock.dart';

import '../hosts/paired_devices_test.dart' show ScriptedAuth;

void main() {
  late ScriptedAuth auth;
  late DateTime now;
  late AppLock lock;

  setUp(() {
    auth = ScriptedAuth();
    now = DateTime.utc(2026, 11, 8, 12);
    lock = AppLock(auth: auth, now: () => now);
  });

  test('off by default: a cold start does not lock', () {
    lock.coldStart(enabled: false);
    expect(lock.locked, isFalse);
  });

  test('on: a cold start locks until the user is verified', () async {
    lock.coldStart(enabled: true);
    expect(lock.locked, isTrue);
    auth.allow = false;
    expect(await lock.unlock(), isFalse);
    expect(lock.locked, isTrue);
    auth.allow = true;
    expect(await lock.unlock(), isTrue);
    expect(lock.locked, isFalse);
    expect(auth.reasons, ['Unlock OpenMosh', 'Unlock OpenMosh']);
  });

  test('resuming after more than 60 s in the background locks', () {
    lock.coldStart(enabled: false); // Turned on later in Settings.
    lock.backgrounded();
    now = now.add(const Duration(seconds: 60));
    lock.resumed(enabled: true);
    expect(lock.locked, isFalse, reason: 'exactly 60 s stays unlocked');
    lock.backgrounded();
    now = now.add(const Duration(seconds: 61));
    lock.resumed(enabled: true);
    expect(lock.locked, isTrue);
  });

  test('resuming after a long background stays unlocked when the lock is off', () {
    lock.coldStart(enabled: false);
    lock.backgrounded();
    now = now.add(const Duration(hours: 1));
    lock.resumed(enabled: false);
    expect(lock.locked, isFalse);
  });

  test('repeated background events keep the first timestamp', () {
    lock.coldStart(enabled: false); // Turned on later in Settings.
    lock.backgrounded();
    now = now.add(const Duration(seconds: 50));
    lock.backgrounded();
    now = now.add(const Duration(seconds: 20));
    lock.resumed(enabled: true);
    expect(lock.locked, isTrue);
  });
}
