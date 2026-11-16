/// Optional app lock (off by default): when on, Falconer asks for user
/// verification on a cold start and after more than [lockAfterBackground]
/// in the background. Pure Dart; the gate widget feeds it lifecycle events.
library;

import '../../../shared/domain/monotonic.dart';
import '../../keys/domain/repositories/key_vault.dart';

const lockAfterBackground = Duration(seconds: 60);

/// Reasons shown in the system verification prompt. Presentation supplies
/// the localized texts; the defaults are English.
final class LockPrompts {
  const LockPrompts({
    this.unlock = 'Unlock Falconer',
    this.turnOn = 'Turn on the Falconer lock',
    this.turnOff = 'Turn off the Falconer lock',
  });

  final String unlock;
  final String turnOn;
  final String turnOff;
}

final class AppLock {
  AppLock({required this.auth, required this.elapsed});

  final UserAuthenticator auth;

  /// Boot clock: counts sleep, and changing the phone's clock cannot skip
  /// the timeout.
  final Elapsed elapsed;

  /// Set by the lock gate from the current locale.
  LockPrompts prompts = const LockPrompts();

  bool _locked = false;
  Future<Duration>? _backgroundSince;

  bool get locked => _locked;

  void coldStart({required bool enabled}) => _locked = enabled;

  /// Keeps the first timestamp when several background events arrive.
  void backgrounded() => _backgroundSince ??= elapsed();

  Future<void> resumed({required bool enabled}) async {
    final since = _backgroundSince;
    _backgroundSince = null;
    if (!enabled || since == null) return;
    final away = await elapsed() - await since;
    // A clock that went back cannot be trusted: lock.
    if (away.isNegative || away > lockAfterBackground) _locked = true;
  }

  /// Verifies the user before the "Lock Falconer" setting changes: turning
  /// it off must not be possible for someone holding an unlocked phone, and
  /// turning it on first proves a credential exists (else the user would be
  /// locked out on the next start). Returns null when the change may be
  /// saved, else why it may not.
  Future<String?> verifyToggle({required bool enable}) async {
    final ok = await auth.authenticate(enable ? prompts.turnOn : prompts.turnOff);
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
    if (await auth.authenticate(prompts.unlock)) _locked = false;
    return !_locked;
  }
}
