import 'dart:typed_data';

import '../entities/ssh_key_info.dart';

/// Device credential / biometric prompt.
abstract interface class UserAuthenticator {
  /// Returns false when the user cancels or no credential is available.
  Future<bool> authenticate(String reason);
}

abstract interface class KeyVault {
  Stream<List<SshKeyInfo>> watchAll();
  Future<SshKeyInfo?> byId(String id);

  /// Creates the device Ed25519 key if missing.
  Future<SshKeyInfo> ensureDeviceKey({required String comment});
  Future<SshKeyInfo> generate(String label);
  Future<SshKeyInfo> import(String label, String privateOpenssh);
  Future<void> delete(String id);

  /// Requires user authentication every call. Throws
  /// `UserCancelledFailure` when the prompt is dismissed.
  Future<String> unlockPrivate(String id, {required String reason});

  /// True when a key still lives in the v0.1 namespace (not auth-bound).
  /// No prompt.
  Future<bool> hasLegacyKeys();

  /// Moves every v0.1 key into the auth-bound namespace; each write shows
  /// the hardware prompt. Returns how many keys moved. A key whose write
  /// fails stays where it was.
  Future<int> migrateLegacyKeys();
}

/// X25519 key that decrypts pushes. Not biometric-gated: the background
/// isolate needs it and it can only decrypt notifications.
abstract interface class PushKeyStore {
  Future<Uint8List> publicKey();
  Future<Uint8List> privateKey();
}
