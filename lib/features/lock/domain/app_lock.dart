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

  /// Returns true when the app is unlocked afterwards.
  Future<bool> unlock() async {
    if (!_locked) return true;
    if (await auth.authenticate('Unlock OpenMosh')) _locked = false;
    return !_locked;
  }
}
