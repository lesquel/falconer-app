import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/datasources/local_notifications.dart';
import 'package:openmosh/features/inbox/domain/entities/suggested_answer.dart';

void main() {
  test('a tap on the notification body opens the event with no answer', () {
    final r = notificationRoute('/inbox/h1/ev1', null);
    expect(r.path, '/inbox/h1/ev1');
    expect(r.answer, isNull);
    expect(notificationRoute('/inbox/h1/ev1', 'open').answer, isNull);
  });

  test('an Approve or Deny button suggests its answer out of the URL', () {
    final r = notificationRoute('/inbox/h1/ev1', 'allow');
    expect(r.path, '/inbox/h1/ev1');
    expect(r.path.contains('action'), isFalse);
    expect(r.answer, const SuggestedAnswer('allow'));
  });

  test('a query in the payload is dropped', () {
    expect(notificationRoute('/inbox/h1/ev1?action=allow', null).path, '/inbox/h1/ev1');
  });
}
