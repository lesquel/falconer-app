import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/lock/domain/app_lock.dart';

import '../hosts/paired_devices_test.dart' show ScriptedAuth;

void main() {
  late ScriptedAuth auth;
  late Duration now;
  late AppLock lock;

  setUp(() {
    auth = ScriptedAuth();
    now = const Duration(hours: 3);
    lock = AppLock(auth: auth, elapsed: () async => now);
  });

  test('off by default: a cold start does not lock', () async {
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

  test('resuming after more than 60 s in the background locks', () async {
    lock.coldStart(enabled: false); // Turned on later in Settings.
    lock.backgrounded();
    now += const Duration(seconds: 60);
    await lock.resumed(enabled: true);
    expect(lock.locked, isFalse, reason: 'exactly 60 s stays unlocked');
    lock.backgrounded();
    now += const Duration(seconds: 61);
    await lock.resumed(enabled: true);
    expect(lock.locked, isTrue);
  });

  test('resuming after a long background stays unlocked when the lock is off', () async {
    lock.coldStart(enabled: false);
    lock.backgrounded();
    now += const Duration(hours: 1);
    await lock.resumed(enabled: false);
    expect(lock.locked, isFalse);
  });

  test('repeated background events keep the first timestamp', () async {
    lock.coldStart(enabled: false); // Turned on later in Settings.
    lock.backgrounded();
    now += const Duration(seconds: 50);
    lock.backgrounded();
    now += const Duration(seconds: 20);
    await lock.resumed(enabled: true);
    expect(lock.locked, isTrue);
  });

  test('turning the lock off requires a successful verification', () async {
    auth.allow = false;
    expect(await lock.verifyToggle(enable: false), isNotNull);
    auth.allow = true;
    expect(await lock.verifyToggle(enable: false), isNull);
    expect(auth.reasons, ['Turn off the OpenMosh lock', 'Turn off the OpenMosh lock']);
  });

  test('turning the lock on first checks that the user can be verified', () async {
    auth.allow = false;
    final why = await lock.verifyToggle(enable: true);
    expect(why, contains('stays off'));
    auth.allow = true;
    expect(await lock.verifyToggle(enable: true), isNull);
    expect(auth.reasons, ['Turn on the OpenMosh lock', 'Turn on the OpenMosh lock']);
  });

  test('a clock that goes back locks instead of skipping the timeout', () async {
    lock.coldStart(enabled: false);
    lock.backgrounded();
    now -= const Duration(hours: 1);
    await lock.resumed(enabled: true);
    expect(lock.locked, isTrue);
  });
}
