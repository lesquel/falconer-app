import 'package:drift/drift.dart';

import '../../../../shared/data/app_database.dart';
import '../../domain/entities/inbox_event.dart';
import '../../domain/repositories/inbox_ports.dart';

class DriftInboxRepository implements InboxRepository {
  DriftInboxRepository(this._db);
  final AppDatabase _db;

  InboxEvent _map(EventRow r) => InboxEvent(
        id: r.id,
        hostId: r.hostId,
        seq: r.seq,
        agent: r.agent,
        kind: EventKind.parse(r.kind) ?? EventKind.done,
        title: r.title,
        summary: r.summary,
        pane: r.pane,
        at: DateTime.fromMillisecondsSinceEpoch(r.at, isUtc: true),
        status: InboxStatus.values.byName(r.status),
        response: r.response == null ? null : ResponseKind.values.byName(r.response!),
      );

  @override
  Stream<List<InboxEvent>> watchAll() => (_db.select(_db.eventRows)
        ..orderBy([(t) => OrderingTerm.desc(t.at), (t) => OrderingTerm.desc(t.seq)])
        ..limit(500))
      .watch()
      .map((rows) => rows.map(_map).toList());

  @override
  Future<InboxEvent?> byId(String hostId, String id) async {
    final r = await (_db.select(_db.eventRows)..where((t) => t.hostId.equals(hostId) & t.id.equals(id)))
        .getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<void> upsert(InboxEvent e) => _db.into(_db.eventRows).insertOnConflictUpdate(EventRowsCompanion.insert(
        hostId: e.hostId,
        id: e.id,
        seq: e.seq,
        agent: e.agent,
        kind: e.kind.wire,
        title: e.title,
        summary: e.summary,
        pane: e.pane,
        at: e.at.millisecondsSinceEpoch,
        status: e.status.name,
        response: Value(e.response?.name),
      ));

  @override
  Future<int> maxSeq(String hostId) async {
    final max = _db.eventRows.seq.max();
    final q = _db.selectOnly(_db.eventRows)
      ..addColumns([max])
      ..where(_db.eventRows.hostId.equals(hostId));
    return (await q.getSingle()).read(max) ?? 0;
  }

  @override
  Future<int> pendingCount() async {
    final n = _db.eventRows.id.count();
    final q = _db.selectOnly(_db.eventRows)
      ..addColumns([n])
      ..where(_db.eventRows.status.isIn(['pending', 'failed']));
    return (await q.getSingle()).read(n) ?? 0;
  }
}
