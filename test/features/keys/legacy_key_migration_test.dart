import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keys/domain/usecases/legacy_key_migration.dart';
import 'package:openmosh/shared/domain/failure.dart';

import '../../support/fakes.dart';
import '../hosts/paired_devices_test.dart' show ScriptedAuth;

void main() {
  late ScriptedAuth inner;
  late FakeVault vault;
  late MigratingAuthenticator auth;

  setUp(() {
    inner = ScriptedAuth();
    vault = FakeVault()..legacyKeys = 2;
    auth = MigratingAuthenticator(inner, vault);
  });

  test('nothing migrates before the startup check finds a v0.1 key', () async {
    expect(await auth.authenticate('r'), isTrue);
    expect(vault.migrations, 0);
  });

  test('a v0.1 key found at startup moves at the next successful verification, once', () async {
    await auth.checkOnStartup();
    inner.allow = false;
    expect(await auth.authenticate('r'), isFalse);
    expect(vault.migrations, 0);
    inner.allow = true;
    expect(await auth.authenticate('r'), isTrue);
    expect(vault.migrations, 1);
    expect(await auth.authenticate('r'), isTrue);
    expect(vault.migrations, 1);
  });

  test('no v0.1 key at startup: no migration', () async {
    vault.legacyKeys = 0;
    await auth.checkOnStartup();
    await auth.authenticate('r');
    expect(vault.migrations, 0);
  });

  test('a cancelled migration is retried at the next verification', () async {
    await auth.checkOnStartup();
    vault.migrationFailure = const UserCancelledFailure();
    expect(await auth.authenticate('r'), isTrue, reason: 'the verification still counts');
    expect(vault.migrations, 1);
    vault.migrationFailure = null;
    await auth.authenticate('r');
    expect(vault.migrations, 2);
    await auth.authenticate('r');
    expect(vault.migrations, 2);
  });
}
