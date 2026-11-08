import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/models/notification_content.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';

InboxEvent e(EventKind kind) => InboxEvent.received(
    id: 'ev1', hostId: 'h1', seq: 1, agent: 'claude', kind: kind,
    title: 'Delete prod DB?', summary: 'DROP TABLE users', pane: 'p', at: DateTime.utc(2026));

void main() {
  test('default notification reveals only alias and agent', () {
    final c = notificationContent(e(EventKind.approvalRequired), hostAlias: 'work', preview: false);
    expect(c.title, 'work: claude needs you');
    expect(c.body, isNull);
    expect(c.lockScreenSafe, isTrue);
    expect('${c.title}${c.body}', isNot(contains('DROP')));
  });

  test('previews show title and summary but are private on the lock screen', () {
    final c = notificationContent(e(EventKind.question), hostAlias: 'work', preview: true);
    expect(c.title, 'work · Delete prod DB?');
    expect(c.body, 'DROP TABLE users');
    expect(c.lockScreenSafe, isFalse);
  });

  test('done events say finished', () {
    expect(notificationContent(e(EventKind.done), hostAlias: 'w', preview: false).title, 'w: claude finished');
  });

  test('ids are stable and payloads carry only ids', () {
    expect(notificationId('h1', 'ev1'), notificationId('h1', 'ev1'));
    expect(notificationId('h1', 'ev1'), isNot(notificationId('h1', 'ev2')));
    expect(notificationPayload('h1', 'ev1', 'allow'), '/inbox/h1/ev1?action=allow');
  });
}
