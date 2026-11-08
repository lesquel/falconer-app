/// Remembers when the user last proved they hold the phone (biometric or
/// device credential), so a live terminal is not shown to whoever picks up
/// an unlocked phone long after.
library;

import '../../../shared/domain/monotonic.dart';
import '../../keys/domain/repositories/key_vault.dart';

/// How long a verification lets a pooled or reused terminal open unasked.
const reverifyAfter = Duration(minutes: 5);

/// Decorates the app's [UserAuthenticator]: every successful prompt counts as
/// a fresh verification. Unlocking an SSH key counts too ([markVerified]).
final class UserPresence implements UserAuthenticator {
  UserPresence({required this.inner, required this.elapsed, this.window = reverifyAfter});

  final UserAuthenticator inner;
  final Elapsed elapsed;
  final Duration window;
  Future<Duration>? _last;

  void markVerified() => _last = elapsed();

  /// True when the last verification is at most [window] old.
  Future<bool> recent() async {
    final last = _last;
    if (last == null) return false;
    final age = await elapsed() - await last;
    return !age.isNegative && age <= window;
  }

  @override
  Future<bool> authenticate(String reason) async {
    final ok = await inner.authenticate(reason);
    if (ok) markVerified();
    return ok;
  }

  /// Asks for verification unless the last one is recent. False when the
  /// user refuses.
  Future<bool> ensureRecent(String reason) async => await recent() || await authenticate(reason);
}
