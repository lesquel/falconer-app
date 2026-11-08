import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/models/notification_content.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:openmosh/features/inbox/data/datasources/local_notifications.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';

InboxEvent e(EventKind kind) => InboxEvent.received(
  id: 'ev1',
  hostId: 'h1',
  seq: 1,
  agent: 'claude',
  kind: kind,
  title: 'Delete prod DB?',
  summary: 'DROP TABLE users',
  pane: 'p',
  at: DateTime.utc(2026),
);

void main() {
  test('default notification reveals only alias and agent', () {
    final c = notificationContent(e(EventKind.approvalRequired), hostAlias: 'work', preview: false);
    expect(c.title, 'work: claude needs you');
    expect(c.body, isNull);
    expect('${c.title}${c.body}', isNot(contains('DROP')));
  });

  test('previews show title and summary but are private on the lock screen', () {
    final c = notificationContent(e(EventKind.question), hostAlias: 'work', preview: true);
    expect(c.title, 'work · Delete prod DB?');
    expect(c.body, 'DROP TABLE users');
  });

  test('done events say finished', () {
    expect(
      notificationContent(e(EventKind.done), hostAlias: 'w', preview: false).title,
      'w: claude finished',
    );
  });

  test('ids are stable and payloads carry only ids', () {
    expect(notificationId('h1', 'ev1'), notificationId('h1', 'ev1'));
    expect(notificationId('h1', 'ev1'), isNot(notificationId('h1', 'ev2')));
    expect(notificationPayload('h1', 'ev1', 'allow'), '/inbox/h1/ev1?action=allow');
  });

  test('payload ids are single encoded segments', () {
    expect(notificationPayload('h1', '../x'), '/inbox/h1/..%2Fx');
  });

  test('every notification is private on the lock screen', () {
    expect(LocalEventNotifier.androidDetails(const []).visibility, NotificationVisibility.private);
  });

  test('the notification body is cut to 200 characters with an ellipsis', () {
    final long = InboxEvent.received(
      id: 'ev1',
      hostId: 'h1',
      seq: 1,
      agent: 'claude',
      kind: EventKind.question,
      title: 't',
      summary: 'x' * 900,
      pane: 'p',
      at: DateTime.utc(2026),
    );
    final c = notificationContent(long, hostAlias: 'w', preview: true);
    expect(c.body!.runes.length, 200);
    expect(c.body!.endsWith('…'), isTrue);
  });
}
