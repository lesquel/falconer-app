import 'package:local_auth/local_auth.dart';

import '../../domain/repositories/key_vault.dart';

/// Biometric or device credential (PIN/pattern) prompt.
class LocalAuthAuthenticator implements UserAuthenticator {
  LocalAuthAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();
  final LocalAuthentication _auth;

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: false);
    } catch (_) {
      return false;
    }
  }
}
