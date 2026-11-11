import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keys/data/datasources/secure_key_storage.dart';
import 'package:openmosh/shared/domain/failure.dart';

class _Mem implements SecretStore {
  final values = <String, String>{};
  PlatformException? failRead;

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async {
    if (failRead != null) throw failRead!;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

void main() {
  test('storage names are pinned: renaming one orphans every stored key', () {
    // Android Keystore namespaces.
    expect(SecureKeyStorage.sshOptions.toMap()['storageNamespace'], 'openmosh_ssh_keys_v2');
    expect(SecureKeyStorage.legacySshOptions.toMap()['storageNamespace'], 'openmosh_ssh_keys');
    expect(SecureKeyStorage.pushOptions.toMap()['storageNamespace'], 'openmosh_push');
    // iOS / macOS keychain services.
    expect(SecureKeyStorage.appleSshOptions.toMap()['accountName'], 'openmosh_ssh_keys_v2');
    expect(
      SecureKeyStorage.appleMacLocalOptions.toMap()['accountName'],
      'openmosh_ssh_keys_v2_local',
    );
    expect(SecureKeyStorage.applePushOptions.toMap()['accountName'], 'openmosh_push');
  });

  test('Apple stores use distinct keychain services and stay device-only', () {
    final ssh = SecureKeyStorage.appleSshOptions.toMap();
    final push = SecureKeyStorage.applePushOptions.toMap();
    final legacy = SecureKeyStorage.appleLegacyOptions.toMap();
    expect({ssh['accountName'], push['accountName'], legacy['accountName']}, hasLength(3));
    expect(ssh['synchronizable'], 'false');
    expect(push['synchronizable'], 'false');
    expect(ssh['accessControlFlags'], '[userPresence]');
    expect(ssh['accessibility'], 'passcode');
    expect(push['accessControlFlags'], isNull);
    expect(push['accessibility'], 'first_unlock_this_device');
  });

  group('push read-through migration', () {
    late _Mem push;
    late _Mem old;
    late SecureKeyStorage storage;
    setUp(() {
      push = _Mem();
      old = _Mem();
      storage = SecureKeyStorage(ssh: _Mem(), legacySsh: _Mem(), push: push, legacyPush: old);
    });

    test('moves a value from the default account on first read', () async {
      old.values['push_x25519_private'] = 'secret';
      expect(await storage.readPush('push_x25519_private'), 'secret');
      expect(push.values['push_x25519_private'], 'secret');
      expect(old.values, isEmpty);
    });

    test('prefers the new account and leaves nothing behind on write', () async {
      push.values['k'] = 'new';
      old.values['k'] = 'stale';
      expect(await storage.readPush('k'), 'new');
      await storage.writePush('k', 'newer');
      expect(old.values, isEmpty);
      expect(push.values['k'], 'newer');
    });

    test('missing everywhere is null; delete clears both', () async {
      expect(await storage.readPush('x'), isNull);
      push.values['x'] = '1';
      old.values['x'] = '2';
      await storage.deletePush('x');
      expect(push.values, isEmpty);
      expect(old.values, isEmpty);
    });

    test('without a legacy push store (Android) nothing is migrated', () async {
      final android = SecureKeyStorage(ssh: _Mem(), legacySsh: _Mem(), push: push);
      expect(await android.readPush('k'), isNull);
    });
  });

  group('keychain errors', () {
    // OSStatus codes only exist on Apple platforms.
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<Object?> failWith(PlatformException e) async {
      final ssh = _Mem()..failRead = e;
      final storage = SecureKeyStorage(ssh: ssh, legacySsh: _Mem(), push: _Mem());
      try {
        await storage.readSshPrivate('a');
      } on Object catch (err) {
        return err;
      }
      return null;
    }

    test('user cancelled (-128) is UserCancelledFailure', () async {
      final e = await failWith(
        PlatformException(code: 'Unexpected security result code', message: 'x', details: -128),
      );
      expect(e, isA<UserCancelledFailure>());
    });

    test('status parsed from the message when details are absent', () async {
      final e = await failWith(
        PlatformException(
          code: 'Unexpected security result code',
          message: 'Code: -25293, Message: x',
        ),
      );
      expect(e, isA<UserCancelledFailure>());
    });

    test('no passcode set (-25291) asks for a screen lock', () async {
      final e = await failWith(
        PlatformException(code: 'Unexpected security result code', message: 'x', details: -25291),
      );
      expect(e, isA<ValidationFailure>());
    });

    test('a locked device (-25308) and a missing entitlement (-34018) are not cancels', () async {
      for (final status in [-25308, -34018]) {
        final e = await failWith(
          PlatformException(code: 'Unexpected security result code', message: 'x', details: status),
        );
        expect(e, isA<ValidationFailure>(), reason: 'OSStatus $status');
      }
    });
  });

  group('macOS missing keychain entitlement (-34018)', () {
    final missing = PlatformException(
      code: 'Unexpected security result code',
      message: 'x',
      details: -34018,
    );

    test('falls back to the local store, stickily, and flags app-level auth', () async {
      final ssh = _Mem()..failRead = missing;
      final local = _Mem();
      final storage = SecureKeyStorage(
        ssh: ssh,
        legacySsh: _Mem(),
        push: _Mem(),
        macLocalSsh: local,
        platform: TargetPlatform.macOS,
      );
      expect(storage.sshFallbackActive, isFalse);
      expect(await storage.readSshPrivate('a'), isNull);
      expect(storage.sshFallbackActive, isTrue);
      await storage.writeSshPrivate('a', 'secret');
      expect(await storage.readSshPrivate('a'), 'secret');
      expect(local.values['ssh:a'], 'secret');
      expect(ssh.values, isEmpty);
      await storage.deleteSshPrivate('a');
      expect(local.values, isEmpty);
    });

    test('a release build refuses instead of storing keys unprotected', () async {
      final ssh = _Mem()..failRead = missing;
      final local = _Mem();
      final storage = SecureKeyStorage(
        ssh: ssh,
        legacySsh: _Mem(),
        push: _Mem(),
        macLocalSsh: local,
        platform: TargetPlatform.macOS,
        allowUnprotectedFallback: false,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await expectLater(storage.readSshPrivate('a'), throwsA(isA<ValidationFailure>()));
      expect(storage.sshFallbackActive, isFalse);
      expect(local.values, isEmpty);
    });

    test('is not used on iOS', () async {
      final ssh = _Mem()..failRead = missing;
      final storage = SecureKeyStorage(
        ssh: ssh,
        legacySsh: _Mem(),
        push: _Mem(),
        macLocalSsh: _Mem(),
        platform: TargetPlatform.iOS,
      );
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await expectLater(storage.readSshPrivate('a'), throwsA(isA<ValidationFailure>()));
      expect(storage.sshFallbackActive, isFalse);
    });
  });
}
