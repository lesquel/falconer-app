import 'dart:typed_data';

import 'package:drift/drift.dart';

import '../../../../shared/crypto/openmosh_crypto.dart' as c;
import '../../../../shared/data/app_database.dart';
import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/failure.dart';
import '../../domain/entities/ssh_key_info.dart';
import '../../domain/repositories/key_vault.dart';
import '../datasources/keys_bridge.dart';
import '../datasources/secure_key_storage.dart';

class SecureKeyVault implements KeyVault {
  SecureKeyVault(this._db, this._storage, this._bridge, this._auth, {required this.newId});

  final AppDatabase _db;
  final SecureKeyStorage _storage;
  final KeysBridge _bridge;
  final UserAuthenticator _auth;
  final String Function() newId;

  SshKeyInfo _map(KeyRow r) => SshKeyInfo(
    id: r.id,
    label: r.label,
    publicKey: r.publicKey,
    fingerprint: r.fingerprint,
    imported: r.imported,
    createdAt: DateTime.fromMillisecondsSinceEpoch(r.createdAt),
  );

  @override
  Stream<List<SshKeyInfo>> watchAll() =>
      _db.select(_db.keyRows).watch().map((rows) => rows.map(_map).toList());

  @override
  Future<SshKeyInfo?> byId(String id) async {
    final r = await (_db.select(_db.keyRows)..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _map(r);
  }

  Future<SshKeyInfo> _store(
    String id,
    String label,
    KeyMaterial m, {
    required bool imported,
  }) async {
    await _storage.writeSshPrivate(id, m.privateOpenssh);
    final row = KeyRowsCompanion.insert(
      id: id,
      label: label,
      publicKey: m.publicOpenssh,
      fingerprint: m.fingerprint,
      imported: imported,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _db.into(_db.keyRows).insertOnConflictUpdate(row);
    return (await byId(id))!;
  }

  @override
  Future<SshKeyInfo> ensureDeviceKey({required String comment}) async {
    final existing = await byId(SshKeyInfo.deviceKeyId);
    if (existing != null &&
        (await _storage.hasBoundSshPrivate(existing.id) ||
            await _storage.hasLegacySshPrivate(existing.id))) {
      return existing;
    }
    return _store(
      SshKeyInfo.deviceKeyId,
      'This device',
      _bridge.generate(comment),
      imported: false,
    );
  }

  @override
  Future<SshKeyInfo> generate(String label) =>
      _store(newId(), label, _bridge.generate('openmosh:$label'), imported: false);

  @override
  Future<SshKeyInfo> import(String label, String privateOpenssh) =>
      _store(newId(), label, _bridge.import(privateOpenssh), imported: true);

  @override
  Future<void> delete(String id) async {
    await _storage.deleteSshPrivate(id);
    await (_db.delete(_db.keyRows)..where((t) => t.id.equals(id))).go();
  }

  static const _missing = ValidationFailure('This key is missing. Pair the host again.');

  /// Bound keys: the storage read itself shows the hardware-enforced prompt.
  /// v0.1 keys (not auth-bound): app-level prompt, then re-wrapped into the
  /// bound namespace and removed from the old one, so this happens once.
  @override
  Future<String> unlockPrivate(String id, {required String reason}) async {
    if (await _storage.hasBoundSshPrivate(id)) {
      return await _storage.readSshPrivate(id) ?? (throw _missing);
    }
    if (!await _storage.hasLegacySshPrivate(id)) throw _missing;
    if (!await _auth.authenticate(reason)) throw const UserCancelledFailure();
    final v = await _storage.readLegacySshPrivate(id);
    if (v == null) throw _missing;
    await _storage.writeSshPrivate(id, v);
    await _storage.deleteLegacySshPrivate(id);
    return v;
  }

  Future<List<String>> _legacyIds() async {
    final ids = await (_db.selectOnly(
      _db.keyRows,
    )..addColumns([_db.keyRows.id])).map((r) => r.read(_db.keyRows.id)!).get();
    return [
      for (final id in ids)
        if (await _storage.hasLegacySshPrivate(id)) id,
    ];
  }

  @override
  Future<bool> hasLegacyKeys() async => (await _legacyIds()).isNotEmpty;

  /// A copy left behind next to a bound key is only removed.
  @override
  Future<int> migrateLegacyKeys() async {
    var moved = 0;
    for (final id in await _legacyIds()) {
      if (!await _storage.hasBoundSshPrivate(id)) {
        final v = await _storage.readLegacySshPrivate(id);
        if (v == null) continue;
        await _storage.writeSshPrivate(id, v);
        moved++;
      }
      await _storage.deleteLegacySshPrivate(id);
    }
    return moved;
  }
}

class SecurePushKeyStore implements PushKeyStore {
  SecurePushKeyStore(this._storage);
  final SecureKeyStorage _storage;
  static const _name = 'push_x25519_private';

  Future<Uint8List> _private() async {
    final stored = await _storage.readPush(_name);
    if (stored != null) return b64uDecode(stored);
    final pair = await c.newX25519KeyPair();
    final priv = await c.x25519PrivateBytes(pair);
    await _storage.writePush(_name, b64uEncode(priv));
    return priv;
  }

  @override
  Future<Uint8List> privateKey() => _private();

  @override
  Future<Uint8List> publicKey() async {
    final priv = await _private();
    final pub = await c.x25519PublicBytes(await c.x25519FromPrivate(priv));
    c.wipe(priv);
    return pub;
  }
}
