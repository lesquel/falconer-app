import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/lock/domain/user_presence.dart';

import '../hosts/paired_devices_test.dart' show ScriptedAuth;

void main() {
  late ScriptedAuth auth;
  late Duration t;
  late UserPresence presence;

  setUp(() {
    auth = ScriptedAuth();
    t = Duration.zero;
    presence = UserPresence(inner: auth, elapsed: () => t);
  });

  test('never verified: asks', () async {
    expect(await presence.ensureRecent('show terminal'), isTrue);
    expect(auth.reasons.length, 1);
  });

  test('a verification less than 5 minutes old is reused without asking', () async {
    await presence.authenticate('answer');
    t = const Duration(minutes: 4, seconds: 59);
    expect(await presence.ensureRecent('show terminal'), isTrue);
    expect(auth.reasons.length, 1);
  });

  test('older than 5 minutes: asks again', () async {
    presence.markVerified();
    t = const Duration(minutes: 5, seconds: 1);
    expect(await presence.ensureRecent('show terminal'), isTrue);
    expect(auth.reasons.length, 1);
  });

  test('a refusal shows nothing and is not remembered', () async {
    auth.allow = false;
    expect(await presence.ensureRecent('show terminal'), isFalse);
    expect(presence.recent, isFalse);
  });

  test('a clock that goes back does not count as recent', () async {
    t = const Duration(minutes: 10);
    presence.markVerified();
    t = const Duration(minutes: 1);
    expect(presence.recent, isFalse);
  });
}
