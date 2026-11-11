/// Keystore-backed storage (flutter_secure_storage).
///
/// SSH private keys live in a namespace whose AES key is generated in Android
/// Keystore with `setUserAuthenticationRequired(true)`: every read or write
/// needs a fresh biometric or device-credential prompt, enforced by the
/// hardware, not only by the app. The push key stays unbound because the
/// background engine must decrypt notifications without a prompt.
library;

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../shared/domain/failure.dart';

/// Minimal key/value secret store; [FlutterSecretStore] in production.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<bool> containsKey(String key);
}

class FlutterSecretStore implements SecretStore {
  const FlutterSecretStore(this._s);
  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
  @override
  Future<bool> containsKey(String key) => _s.containsKey(key: key);
}

class SecureKeyStorage {
  SecureKeyStorage({SecretStore? ssh, SecretStore? legacySsh, SecretStore? push})
    : _ssh = ssh ?? const FlutterSecretStore(FlutterSecureStorage(aOptions: sshOptions)),
      _legacySsh =
          legacySsh ?? const FlutterSecretStore(FlutterSecureStorage(aOptions: legacySshOptions)),
      _push = push ?? const FlutterSecretStore(FlutterSecureStorage(aOptions: pushOptions));

  /// Hardware-bound SSH key namespace. `resetOnError` is off: a cancelled or
  /// failed prompt must never wipe the keys.
  static const sshOptions = AndroidOptions.biometric(
    storageNamespace: 'openmosh_ssh_keys_v2',
    enforceBiometrics: true,
    requireBiometricsPerOperation: true,
    resetOnError: false,
    biometricPromptTitle: 'Unlock SSH key',
    biometricPromptSubtitle: 'OpenMosh needs your fingerprint, face or screen lock',
  );

  /// v0.1 namespace (Keystore-wrapped, not auth-bound). Keys found here are
  /// moved to [sshOptions] on their first successful unlock.
  static const legacySshOptions = AndroidOptions(storageNamespace: 'openmosh_ssh_keys');

  static const pushOptions = AndroidOptions(storageNamespace: 'openmosh_push');

  final SecretStore _ssh;
  final SecretStore _legacySsh;
  final SecretStore _push;

  static String _k(String id) => 'ssh:$id';

  /// Prompts (hardware-enforced).
  Future<void> writeSshPrivate(String id, String value) => _guard(() => _ssh.write(_k(id), value));

  /// Prompts (hardware-enforced).
  Future<String?> readSshPrivate(String id) => _guard(() => _ssh.read(_k(id)));

  /// No prompt: presence only.
  Future<bool> hasBoundSshPrivate(String id) => _ssh.containsKey(_k(id));

  Future<bool> hasLegacySshPrivate(String id) => _legacySsh.containsKey(_k(id));
  Future<String?> readLegacySshPrivate(String id) => _legacySsh.read(_k(id));
  Future<void> deleteLegacySshPrivate(String id) => _legacySsh.delete(_k(id));

  Future<void> deleteSshPrivate(String id) async {
    await _ssh.delete(_k(id));
    await _legacySsh.delete(_k(id));
  }

  Future<String?> readPush(String name) => _push.read(name);
  Future<void> writePush(String name, String value) => _push.write(name, value);
  Future<void> deletePush(String name) => _push.delete(name);

  static Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PlatformException catch (e) {
      final detail = '${e.code} ${e.message}';
      if (detail.contains('BIOMETRIC_UNAVAILABLE')) {
        throw const ValidationFailure(
          'Set a screen lock (PIN, pattern, password or biometrics) to store SSH keys.',
        );
      }
      if (detail.contains('KeyPermanentlyInvalidated')) {
        throw const ValidationFailure(
          'The screen lock or biometrics changed, so this key can no longer be unlocked. '
          'Pair the host again.',
        );
      }
      throw const UserCancelledFailure();
    }
  }
}
