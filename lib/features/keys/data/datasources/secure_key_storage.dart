/// Keystore-backed storage (flutter_secure_storage).
///
/// SSH private keys live in a namespace whose AES key is generated in Android
/// Keystore with `setUserAuthenticationRequired(true)`: every read or write
/// needs a fresh biometric or device-credential prompt, enforced by the
/// hardware, not only by the app. The push key stays unbound because the
/// background engine must decrypt notifications without a prompt.
library;

import 'package:flutter/foundation.dart';
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
  SecureKeyStorage({
    SecretStore? ssh,
    SecretStore? legacySsh,
    SecretStore? push,
    SecretStore? legacyPush,
    this._macLocalSsh,
    TargetPlatform? platform,
    this.allowUnprotectedFallback = kDebugMode,
  }) : _platform = platform,
       _ssh = ssh ?? _store(sshOptions, appleSshOptions),
       _legacySsh = legacySsh ?? _store(legacySshOptions, appleLegacyOptions),
       _push = push ?? _store(pushOptions, applePushOptions),
       // Only Apple platforms ever wrote push data to the plugin's default
       // account; Android keeps its own namespaces untouched.
       _legacyPush =
           legacyPush ?? (_isApple(platform) ? _store(pushOptions, appleLegacyOptions) : null);

  final TargetPlatform? _platform;
  SecretStore? _macLocalSsh;

  /// Whether an unsigned macOS build may keep SSH keys in the legacy keychain
  /// (no access control). Debug builds only: a release build refuses instead of
  /// silently storing keys without the keychain's own protection.
  final bool allowUnprotectedFallback;

  /// True once a macOS debug build without the `keychain-access-groups` entitlement
  /// (unsigned / ad-hoc) was detected: SSH keys then live in the legacy
  /// file-based keychain with no access control, so the caller must
  /// authenticate the user before each read.
  bool get sshFallbackActive => _fallbackActive;
  bool _fallbackActive = false;

  bool get _isMac => (_platform ?? defaultTargetPlatform) == TargetPlatform.macOS;

  static bool _isApple(TargetPlatform? platform) {
    final p = platform ?? defaultTargetPlatform;
    return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  }

  static SecretStore _store(
    AndroidOptions android,
    AppleOptions apple, {
    bool dataProtection = true,
  }) => FlutterSecretStore(
    FlutterSecureStorage(
      aOptions: android,
      iOptions: IOSOptions(
        accountName: apple.accountName,
        accessibility: apple.accessibility,
        synchronizable: apple.synchronizable,
        accessControlFlags: apple.accessControlFlags,
      ),
      mOptions: MacOsOptions(
        accountName: apple.accountName,
        accessibility: apple.accessibility,
        synchronizable: apple.synchronizable,
        accessControlFlags: apple.accessControlFlags,
        usesDataProtectionKeychain: dataProtection,
      ),
    ),
  );

  /// macOS without the keychain entitlement: legacy file-based keychain, no
  /// access control (the app authenticates instead). Never used on iOS.
  static const appleMacLocalOptions = IOSOptions(
    accountName: 'openmosh_ssh_keys_v2_local',
    synchronizable: false,
  );

  /// Hardware-bound SSH key namespace. `resetOnError` is off: a cancelled or
  /// failed prompt must never wipe the keys.
  static const sshOptions = AndroidOptions.biometric(
    storageNamespace: 'openmosh_ssh_keys_v2',
    enforceBiometrics: true,
    requireBiometricsPerOperation: true,
    resetOnError: false,
    biometricPromptTitle: 'Unlock SSH key',
    biometricPromptSubtitle: 'Falconer needs your fingerprint, face or screen lock',
  );

  /// v0.1 namespace (Keystore-wrapped, not auth-bound). Keys found here are
  /// moved to [sshOptions] on their first successful unlock.
  static const legacySshOptions = AndroidOptions(storageNamespace: 'openmosh_ssh_keys');

  static const pushOptions = AndroidOptions(storageNamespace: 'openmosh_push');

  // --- iOS / macOS -------------------------------------------------------
  // `accountName` is the keychain `kSecAttrService`, the only thing that
  // separates the stores there (Android's `storageNamespace` is ignored).

  /// SSH keys: this device only, never synced to iCloud, and every read needs
  /// Face ID / Touch ID or the device passcode (`userPresence` access control,
  /// enforced by the Secure Enclave / keychain, not only by the app). The
  /// passcode accessibility class makes the item unusable (and unwritable) if
  /// the passcode is removed. Limitation: unlike Android there is no per-read
  /// freshness guarantee; iOS may cache a successful authentication briefly.
  static const appleSshOptions = IOSOptions(
    accountName: 'openmosh_ssh_keys_v2',
    accessibility: KeychainAccessibility.passcode,
    synchronizable: false,
    accessControlFlags: [AccessControlFlag.userPresence],
  );

  /// Push key and web-push registration: the background engine must decrypt
  /// notifications without a prompt, so no access control; still device-only
  /// and available after the first unlock.
  static const applePushOptions = IOSOptions(
    accountName: 'openmosh_push',
    accessibility: KeychainAccessibility.first_unlock_this_device,
    synchronizable: false,
  );

  /// The plugin's default account: where builds before this hardening wrote
  /// every SSH key (unprotected) and the push data.
  static const appleLegacyOptions = IOSOptions();

  final SecretStore _ssh;
  final SecretStore _legacySsh;
  final SecretStore _push;
  final SecretStore? _legacyPush;

  static String _k(String id) => 'ssh:$id';

  SecretStore get _local =>
      _macLocalSsh ??= _store(sshOptions, appleMacLocalOptions, dataProtection: false);

  /// Runs [op] on the SSH store. On macOS, `errSecMissingEntitlement` (-34018)
  /// means this build has no signing team: switch (once, sticky) to the local
  /// file-keychain store and repeat there. Never on iOS or Android.
  Future<T> _onSsh<T>(Future<T> Function(SecretStore s) op) async {
    if (_isMac && _fallbackActive) return op(_local);
    try {
      return await op(_ssh);
    } on PlatformException catch (e) {
      if (!_isMac || _keychainStatus(e) != _errSecMissingEntitlement) rethrow;
      if (!allowUnprotectedFallback) {
        throw const ValidationFailure(
          'This macOS build is not signed with a team, so it cannot use the protected keychain '
          'for SSH keys. Sign it with your Apple team (apple/Signing.local.xcconfig) and rebuild.',
        );
      }
      _fallbackActive = true;
      debugPrint(
        'openmosh WARNING: keychain-access-groups entitlement missing (-34018); this DEBUG build '
        'stores SSH keys in the legacy keychain with no access control, behind an in-app unlock '
        'only. Sign with a team (apple/Signing.local.xcconfig) to use the protected keychain.',
      );
      return op(_local);
    }
  }

  /// The old default-account store lives in the data-protection keychain too,
  /// so unsigned macOS builds cannot read it: nothing to migrate there.
  Future<T> _legacy<T>(Future<T> Function() op, T orElse) async {
    try {
      return await op();
    } on PlatformException catch (e) {
      if (_isMac && _keychainStatus(e) == _errSecMissingEntitlement) return orElse;
      rethrow;
    }
  }

  /// Prompts (hardware-enforced); on the macOS fallback the caller prompts.
  Future<void> writeSshPrivate(String id, String value) =>
      _guard(() => _onSsh((s) => s.write(_k(id), value)));

  /// Prompts (hardware-enforced); on the macOS fallback the caller prompts.
  Future<String?> readSshPrivate(String id) => _guard(() => _onSsh((s) => s.read(_k(id))));

  /// No prompt: presence only.
  Future<bool> hasBoundSshPrivate(String id) => _guard(() => _onSsh((s) => s.containsKey(_k(id))));

  Future<bool> hasLegacySshPrivate(String id) =>
      _legacy(() => _legacySsh.containsKey(_k(id)), false);
  Future<String?> readLegacySshPrivate(String id) => _legacy(() => _legacySsh.read(_k(id)), null);
  Future<void> deleteLegacySshPrivate(String id) => _legacy(() => _legacySsh.delete(_k(id)), null);

  Future<void> deleteSshPrivate(String id) async {
    await _onSsh((s) => s.delete(_k(id)));
    await deleteLegacySshPrivate(id);
  }

  /// Read-through migration (Apple only): a value still in the default
  /// account is moved to the push account on first read.
  Future<String?> readPush(String name) async {
    final v = await _push.read(name);
    final old = _legacyPush;
    if (v != null || old == null) return v;
    final moved = await old.read(name);
    if (moved == null) return null;
    await _push.write(name, moved);
    await old.delete(name);
    return moved;
  }

  Future<void> writePush(String name, String value) async {
    await _push.write(name, value);
    await _legacyPush?.delete(name);
  }

  Future<void> deletePush(String name) async {
    await _push.delete(name);
    await _legacyPush?.delete(name);
  }

  static Future<T> _guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on PlatformException catch (e) {
      final detail = '${e.code} ${e.message}';
      final code = _isApple(null) ? _keychainStatus(e) : null;
      if (code != null) {
        switch (code) {
          case _errSecUserCanceled || _errSecAuthFailed:
            throw const UserCancelledFailure();
          case _errSecNotAvailable:
            throw const ValidationFailure(
              'Set a screen lock (PIN, pattern, password or biometrics) to store SSH keys.',
            );
          case _errSecInteractionNotAllowed:
            throw const ValidationFailure('Unlock this device and try again.');
          default:
            // Not a cancel: surface it so a real keychain problem (e.g. a
            // missing entitlement) is not mistaken for the user backing out.
            throw ValidationFailure('The keychain refused the operation (OSStatus $code).');
        }
      }
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

  /// `errSecNotAvailable`: no passcode is set on the device.
  static const _errSecNotAvailable = -25291;

  /// `errSecUserCanceled` / `errSecAuthFailed`: the prompt was dismissed or failed.
  static const _errSecUserCanceled = -128;
  static const _errSecAuthFailed = -25293;

  /// `errSecMissingEntitlement`: unsigned macOS build (no keychain-access-groups).
  static const _errSecMissingEntitlement = -34018;

  /// `errSecInteractionNotAllowed`: the device is locked.
  static const _errSecInteractionNotAllowed = -25308;

  /// OSStatus reported by the Darwin plugin (`details`, or "Code: -128" in the
  /// message); null on Android.
  static int? _keychainStatus(PlatformException e) {
    final d = e.details;
    if (d is int) return d;
    final m = RegExp(r'Code: (-?\d+)').firstMatch(e.message ?? '');
    return m == null ? null : int.parse(m.group(1)!);
  }
}
