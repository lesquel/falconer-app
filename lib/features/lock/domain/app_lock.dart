/// Optional app lock (off by default): when on, OpenMosh asks for user
/// verification on a cold start and after more than [lockAfterBackground]
/// in the background. Pure Dart; the gate widget feeds it lifecycle events.
library;

import '../../../shared/domain/clock.dart';
import '../../keys/domain/repositories/key_vault.dart';

const lockAfterBackground = Duration(seconds: 60);

final class AppLock {
  AppLock({required this.auth, required this.now});

  final UserAuthenticator auth;
  final Clock now;

  bool _locked = false;
  DateTime? _backgroundSince;

  bool get locked => _locked;

  void coldStart({required bool enabled}) => _locked = enabled;

  /// Keeps the first timestamp when several background events arrive.
  void backgrounded() => _backgroundSince ??= now();

  void resumed({required bool enabled}) {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (enabled && since != null && now().difference(since) > lockAfterBackground) {
      _locked = true;
    }
  }

  /// Verifies the user before the "Lock OpenMosh" setting changes: turning
  /// it off must not be possible for someone holding an unlocked phone, and
  /// turning it on first proves a credential exists (else the user would be
  /// locked out on the next start). Returns null when the change may be
  /// saved, else why it may not.
  Future<String?> verifyToggle({required bool enable}) async {
    final ok = await auth.authenticate(
      enable ? 'Turn on the OpenMosh lock' : 'Turn off the OpenMosh lock',
    );
    if (ok) {
      // The prompt may have backgrounded the app; the user was just verified.
      _backgroundSince = null;
      return null;
    }
    return enable
        ? 'Could not verify you, so the lock stays off. Set up a fingerprint, face or screen '
              'lock on this phone, then try again.'
        : 'Could not verify you, so the lock stays on.';
  }

  /// Returns true when the app is unlocked afterwards.
  Future<bool> unlock() async {
    if (!_locked) return true;
    if (await auth.authenticate('Unlock OpenMosh')) _locked = false;
    return !_locked;
  }
}
