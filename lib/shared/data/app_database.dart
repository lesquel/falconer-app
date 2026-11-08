/// Local SQLite store (drift): hosts, key metadata, inbox cache, settings.
/// Private keys are NOT stored here; they live in Keystore-backed storage.
library;

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class HostRows extends Table {
  @override
  String get tableName => 'hosts';

  TextColumn get id => text()();
  TextColumn get alias => text()();
  TextColumn get address => text()();
  IntColumn get port => integer()();
  TextColumn get username => text()();
  TextColumn get keyId => text().nullable()();
  TextColumn get fingerprint => text()();
  TextColumn get hookPath => text().nullable()();
  TextColumn get deviceId => text().nullable()();
  TextColumn get hostPushKey => text().nullable()();
  TextColumn get pairedVia => text()();
  TextColumn get endpointSent => text().nullable()();
  TextColumn get lastAttach => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class KeyRows extends Table {
  @override
  String get tableName => 'ssh_keys';

  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get publicKey => text()();
  TextColumn get fingerprint => text()();
  BoolColumn get imported => boolean()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class EventRows extends Table {
  @override
  String get tableName => 'inbox_events';

  TextColumn get hostId => text()();
  TextColumn get id => text()();
  IntColumn get seq => integer()();
  TextColumn get agent => text()();
  TextColumn get kind => text()();
  TextColumn get title => text()();
  TextColumn get summary => text()();
  TextColumn get pane => text()();
  IntColumn get at => integer()();
  TextColumn get status => text()();
  TextColumn get response => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {hostId, id};
}

class SettingRows extends Table {
  @override
  String get tableName => 'settings';

  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(tables: [HostRows, KeyRows, EventRows, SettingRows])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Shared across isolates so the background push handler and the UI can
  /// use the same file safely.
  factory AppDatabase.open() => AppDatabase(
        driftDatabase(
          name: 'openmosh',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ),
      );

  @override
  int get schemaVersion => 1;
}
