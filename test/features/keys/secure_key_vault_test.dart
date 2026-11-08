import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keys/data/datasources/keys_bridge.dart';
import 'package:openmosh/features/keys/data/datasources/secure_key_storage.dart';
import 'package:openmosh/features/keys/data/repositories/secure_key_vault.dart';
import 'package:openmosh/features/keys/domain/repositories/key_vault.dart';
import 'package:openmosh/shared/data/app_database.dart';
import 'package:openmosh/shared/domain/failure.dart';

class MemStore implements SecretStore {
  final values = <String, String>{};
  int reads = 0;
  int writes = 0;
  PlatformException? fail;

  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async {
    reads++;
    if (fail != null) throw fail!;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writes++;
    if (fail != null) throw fail!;
    values[key] = value;
  }
}

class CountingAuth implements UserAuthenticator {
  int calls = 0;
  bool allow = true;
  @override
  Future<bool> authenticate(String reason) async {
    calls++;
    return allow;
  }
}

void main() {
  late MemStore bound;
  late MemStore legacy;
  late CountingAuth auth;
  late SecureKeyVault vault;
  late AppDatabase db;

  setUp(() {
    bound = MemStore();
    legacy = MemStore();
    auth = CountingAuth();
    db = AppDatabase(NativeDatabase.memory());
    vault = SecureKeyVault(
      db,
      SecureKeyStorage(ssh: bound, legacySsh: legacy, push: MemStore()),
      const KeysBridge(),
      auth,
      newId: () => 'k1',
    );
  });
  tearDown(() => db.close());

  test('SSH keys use a hardware auth-bound namespace; the push key does not', () {
    final ssh = SecureKeyStorage.sshOptions.toMap();
    expect(ssh['enforceBiometrics'], 'true');
    expect(ssh['requireBiometricsPerOperation'], 'true');
    expect(ssh['keyCipherAlgorithm'], 'AES_GCM_NoPadding');
    expect(ssh['resetOnError'], 'false');
    final push = SecureKeyStorage.pushOptions.toMap();
    expect(push['enforceBiometrics'], 'false');
    expect(push['storageNamespace'], 'openmosh_push');
    expect(ssh['storageNamespace'], isNot(SecureKeyStorage.legacySshOptions.storageNamespace));
  });

  test('a bound key is unlocked by the hardware prompt of the read itself', () async {
    bound.values['ssh:k1'] = 'PRIV';
    expect(await vault.unlockPrivate('k1', reason: 'r'), 'PRIV');
    expect(bound.reads, 1);
    expect(auth.calls, 0);
  });

  test('a cancelled hardware prompt is a UserCancelledFailure and keeps the key', () async {
    bound.values['ssh:k1'] = 'PRIV';
    bound.fail = PlatformException(code: 'Exception encountered', message: 'cancelled');
    await expectLater(vault.unlockPrivate('k1', reason: 'r'), throwsA(isA<UserCancelledFailure>()));
    expect(bound.values, {'ssh:k1': 'PRIV'});
  });

  test('a v0.1 key is re-wrapped into the bound namespace on first unlock', () async {
    legacy.values['ssh:k1'] = 'OLD';
    expect(await vault.unlockPrivate('k1', reason: 'r'), 'OLD');
    expect(auth.calls, 1);
    expect(bound.values, {'ssh:k1': 'OLD'});
    expect(legacy.values, isEmpty);
    expect(await vault.unlockPrivate('k1', reason: 'r'), 'OLD');
    expect(auth.calls, 1);
  });

  test('a v0.1 key is not migrated when the user cancels', () async {
    legacy.values['ssh:k1'] = 'OLD';
    auth.allow = false;
    await expectLater(vault.unlockPrivate('k1', reason: 'r'), throwsA(isA<UserCancelledFailure>()));
    expect(legacy.values, {'ssh:k1': 'OLD'});
    expect(bound.values, isEmpty);
  });

  test('a v0.1 key whose re-wrap fails stays in the legacy namespace', () async {
    legacy.values['ssh:k1'] = 'OLD';
    bound.fail = PlatformException(code: 'x', message: 'cancelled');
    await expectLater(vault.unlockPrivate('k1', reason: 'r'), throwsA(isA<UserCancelledFailure>()));
    expect(legacy.values, {'ssh:k1': 'OLD'});
  });

  test('a missing key asks to pair again', () async {
    await expectLater(
      vault.unlockPrivate('k1', reason: 'r'),
      throwsA(isA<ValidationFailure>().having((e) => e.message, 'm', contains('Pair the host'))),
    );
  });

  test('no screen lock surfaces a clear message', () async {
    bound.values['ssh:k1'] = 'PRIV';
    bound.fail = PlatformException(code: 'e', message: 'BIOMETRIC_UNAVAILABLE: no PIN');
    await expectLater(
      vault.unlockPrivate('k1', reason: 'r'),
      throwsA(isA<ValidationFailure>().having((e) => e.message, 'm', contains('screen lock'))),
    );
  });

  test('delete removes the key from both namespaces', () async {
    bound.values['ssh:k1'] = 'A';
    legacy.values['ssh:k1'] = 'B';
    await vault.delete('k1');
    expect(bound.values, isEmpty);
    expect(legacy.values, isEmpty);
  });
}
