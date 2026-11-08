import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';

InboxEvent event({EventKind kind = EventKind.approvalRequired}) => InboxEvent.received(
      id: 'ev1',
      hostId: 'h1',
      seq: 3,
      agent: 'claude',
      kind: kind,
      title: 'Run tests?',
      summary: 'cargo test',
      pane: 'p1',
      at: DateTime.utc(2026),
    );

void main() {
  test('actionable kinds start pending, done starts informational', () {
    expect(event().status, InboxStatus.pending);
    expect(event(kind: EventKind.question).status, InboxStatus.pending);
    expect(event(kind: EventKind.done).status, InboxStatus.info);
    expect(event().needsAction, isTrue);
    expect(event(kind: EventKind.done).needsAction, isFalse);
  });

  test('pending -> responding -> resolved records the answer', () {
    final r = event().startResponding(ResponseKind.allow);
    expect(r.status, InboxStatus.responding);
    final done = r.responseSucceeded();
    expect(done.status, InboxStatus.resolved);
    expect(done.response, ResponseKind.allow);
  });

  test('a failed response can be retried', () {
    final failed = event().startResponding(ResponseKind.deny).responseFailed();
    expect(failed.status, InboxStatus.failed);
    expect(failed.startResponding(ResponseKind.allow).status, InboxStatus.responding);
  });

  test('illegal transitions throw', () {
    expect(() => event().responseSucceeded(), throwsA(isA<InvalidTransition>()));
    expect(() => event().responseFailed(), throwsA(isA<InvalidTransition>()));
    expect(() => event(kind: EventKind.done).startResponding(ResponseKind.allow),
        throwsA(isA<InvalidTransition>()));
    final resolved = event().startResponding(ResponseKind.allow).responseSucceeded();
    expect(() => resolved.startResponding(ResponseKind.deny), throwsA(isA<InvalidTransition>()));
    final busy = event().startResponding(ResponseKind.allow);
    expect(() => busy.startResponding(ResponseKind.deny), throwsA(isA<InvalidTransition>()));
  });

  test('resolved elsewhere wins from any state and keeps a local answer', () {
    expect(event().resolvedElsewhere().status, InboxStatus.resolved);
    expect(event().resolvedElsewhere().response, isNull);
    final mine = event().startResponding(ResponseKind.allow).responseSucceeded();
    expect(mine.resolvedElsewhere().response, ResponseKind.allow);
  });

  test('a duplicate delivery never moves an event backwards', () {
    final resolved = event().resolvedElsewhere();
    expect(resolved.mergeIncoming(event()).status, InboxStatus.resolved);
    expect(event().mergeIncoming(event()).status, InboxStatus.pending);
  });

  test('kind parsing follows the wire names', () {
    expect(EventKind.parse('approval_required'), EventKind.approvalRequired);
    expect(EventKind.parse('question'), EventKind.question);
    expect(EventKind.parse('done'), EventKind.done);
    expect(EventKind.parse('resolved'), EventKind.resolved);
    expect(EventKind.parse('weird'), isNull);
  });
}
