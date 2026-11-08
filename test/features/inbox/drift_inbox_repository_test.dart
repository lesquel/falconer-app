import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/data/repositories/drift_inbox_repository.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';
import 'package:openmosh/shared/data/app_database.dart';

InboxEvent event(String id, {String hostId = 'h1', int seq = 1}) => InboxEvent(
  id: id,
  hostId: hostId,
  seq: seq,
  agent: 'claude',
  kind: EventKind.question,
  title: 'Which DB?',
  summary: 'pick one',
  pane: 'p1',
  at: DateTime.fromMillisecondsSinceEpoch(1762500000000, isUtc: true),
  status: InboxStatus.pending,
);

void main() {
  late AppDatabase db;
  late DriftInboxRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftInboxRepository(db);
  });
  tearDown(() => db.close());

  test('upsertAll stores a page and byIds reads it back per host', () async {
    await repo.upsertAll([event('a'), event('b', seq: 2), event('a', hostId: 'h2', seq: 3)]);
    await repo.upsertAll([event('b', seq: 4)]);
    final got = await repo.byIds('h1', ['a', 'b', 'missing']);
    expect(got.keys, unorderedEquals(['a', 'b']));
    expect(got['b']!.seq, 4, reason: 'an existing row is updated');
    expect((await repo.byIds('h2', ['a']))['a']!.seq, 3);
    expect(await repo.byIds('h1', const []), isEmpty);
  });
}
