import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/datasources/local_notifications.dart';
import 'package:openmosh/features/inbox/data/models/notification_tag.dart';
import 'package:openmosh/features/inbox/domain/entities/suggested_answer.dart';
import 'package:openmosh/features/keys/data/datasources/secure_key_storage.dart';

void main() {
  final tagger = NotificationTagger(List<int>.generate(32, (i) => i));
  final other = NotificationTagger(List<int>.generate(32, (i) => 255 - i));
  String own(String host, String event) => signedNotificationPayload(tagger, host, event);

  void expectHome(NotificationRoute r) {
    expect(r.path, '/');
    expect(r.answer, isNull);
  }

  test('a tap on the notification body opens the event with no answer', () {
    final r = notificationRoute(own('h1', 'ev1'), null, tagger);
    expect(r.path, '/inbox/h1/ev1');
    expect(r.answer, isNull);
    expect(notificationRoute(own('h1', 'ev1'), 'open', tagger).answer, isNull);
  });

  test("the app's own Approve or Deny button opens its event with that answer", () {
    final r = notificationRoute(own('h1', 'ev1'), 'allow', tagger);
    expect(r.path, '/inbox/h1/ev1');
    expect(r.path.contains('action'), isFalse);
    expect(r.answer, const SuggestedAnswer('allow'));
    expect(
      notificationRoute(own('h1', 'ev1'), 'deny', tagger).answer,
      const SuggestedAnswer('deny'),
    );
  });

  test('a forged payload without a tag opens home and ignores the action', () {
    expectHome(notificationRoute('/inbox/h1/ev1', 'allow', tagger));
    expectHome(notificationRoute('/inbox/h1/ev1|', 'allow', tagger));
    expectHome(notificationRoute('', 'allow', tagger));
  });

  test('a wrong tag opens home', () {
    final foreign = signedNotificationPayload(other, 'h1', 'ev1');
    expectHome(notificationRoute(foreign, 'allow', tagger));
    final mine = own('h1', 'ev1');
    final flipped = '${mine.substring(0, mine.length - 1)}${mine.endsWith('A') ? 'B' : 'A'}';
    expectHome(notificationRoute(flipped, 'allow', tagger));
    // A valid tag moved onto another event does not open that event.
    final tag = mine.substring(mine.lastIndexOf('|'));
    expectHome(notificationRoute('/inbox/h1/ev2$tag', 'allow', tagger));
  });

  test('a non-inbox route opens home even with a valid tag', () {
    for (final route in [
      '/settings',
      '/',
      '/inbox',
      '/inbox/h1',
      '/inbox/h1/ev1/x',
      '/inbox/h1/ev1?action=allow',
      '/inbox/h1/..%2Fx',
      '/hosts/h1/ev1',
      'https://evil.example/inbox/h1/ev1',
    ]) {
      expectHome(notificationRoute(tagger.sign(route), 'allow', tagger));
    }
  });

  test('the per-install key is created once in the push namespace and reused', () async {
    final push = _MemStore();
    final storage = SecureKeyStorage(
      ssh: _MemStore(),
      legacySsh: _MemStore(),
      push: push,
      legacyPush: _MemStore(),
    );
    final first = await NotificationTagger.load(storage);
    expect(push.values.keys, [NotificationTagger.storageKey]);
    final second = await NotificationTagger.load(storage);
    final payload = signedNotificationPayload(first, 'h1', 'ev1');
    expect(notificationRoute(payload, 'allow', second).path, '/inbox/h1/ev1');
    expect(push.values.keys, hasLength(1));
  });
}

class _MemStore implements SecretStore {
  final values = <String, String>{};
  @override
  Future<bool> containsKey(String key) async => values.containsKey(key);
  @override
  Future<void> delete(String key) async => values.remove(key);
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
}
