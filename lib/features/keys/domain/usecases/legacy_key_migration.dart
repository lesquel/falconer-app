/// Eager move of v0.1 SSH keys (Keystore-wrapped but not auth-bound) into
/// the auth-bound namespace. Without it a key would stay in the old
/// namespace until its first use; with it, the move happens right after the
/// next successful user verification of any sensitive action.
library;

import '../repositories/key_vault.dart';

final class MigratingAuthenticator implements UserAuthenticator {
  MigratingAuthenticator(this._inner, this._vault);

  final UserAuthenticator _inner;
  final KeyVault _vault;
  bool _pending = false;

  /// Presence check only (no prompt); arms the migration when needed.
  Future<void> checkOnStartup() async {
    try {
      _pending = await _vault.hasLegacyKeys();
    } catch (_) {
      _pending = false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    final ok = await _inner.authenticate(reason);
    if (ok && _pending) {
      _pending = false;
      try {
        await _vault.migrateLegacyKeys();
      } catch (_) {
        // Cancelled or failed: the key stays put; try again next time.
        _pending = true;
      }
    }
    return ok;
  }
}
