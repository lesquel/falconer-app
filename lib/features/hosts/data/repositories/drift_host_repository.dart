import 'package:drift/drift.dart';

import '../../../../shared/data/app_database.dart';
import '../../domain/entities/host.dart';
import '../../domain/repositories/host_repository.dart';

class DriftHostRepository implements HostRepository {
  DriftHostRepository(this._db);
  final AppDatabase _db;

  Host _map(HostRow r) => Host(
        id: r.id,
        alias: r.alias,
        address: r.address,
        port: r.port,
        user: r.username,
        fingerprint: r.fingerprint,
        pairedVia: PairedVia.values.byName(r.pairedVia),
        createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
        keyId: r.keyId,
        hookPath: r.hookPath,
        deviceId: r.deviceId,
        hostPushKey: r.hostPushKey,
        endpointSent: r.endpointSent,
        lastAttach: r.lastAttach,
      );

  HostRowsCompanion _row(Host h) => HostRowsCompanion.insert(
        id: h.id,
        alias: h.alias,
        address: h.address,
        port: h.port,
        username: h.user,
        fingerprint: h.fingerprint,
        pairedVia: h.pairedVia.name,
        createdAt: h.createdAt.millisecondsSinceEpoch,
        keyId: Value(h.keyId),
        hookPath: Value(h.hookPath),
        deviceId: Value(h.deviceId),
        hostPushKey: Value(h.hostPushKey),
        endpointSent: Value(h.endpointSent),
        lastAttach: Value(h.lastAttach),
      );

  @override
  Stream<List<Host>> watchAll() => (_db.select(_db.hostRows)..orderBy([(t) => OrderingTerm.asc(t.alias)]))
      .watch()
      .map((rows) => rows.map(_map).toList());

  @override
  Future<List<Host>> all() async => (await _db.select(_db.hostRows).get()).map(_map).toList();

  @override
  Future<Host?> byId(String id) async {
    final r = await (_db.select(_db.hostRows)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<Host?> byDeviceId(String deviceId) async {
    final r = await (_db.select(_db.hostRows)..where((t) => t.deviceId.equals(deviceId)))
        .getSingleOrNull();
    return r == null ? null : _map(r);
  }

  @override
  Future<void> save(Host host) => _db.into(_db.hostRows).insertOnConflictUpdate(_row(host));

  @override
  Future<void> delete(String id) async {
    await (_db.delete(_db.eventRows)..where((t) => t.hostId.equals(id))).go();
    await (_db.delete(_db.hostRows)..where((t) => t.id.equals(id))).go();
  }
}
