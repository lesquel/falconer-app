import 'dart:convert';

import '../../keys/data/datasources/secure_key_storage.dart';
import '../domain/entities/webpush_delivery.dart';
import '../domain/entities/webpush_registration.dart';
import '../domain/repositories/webpush_store.dart';

/// Keeps the registration (private key inside) and delivery records in the
/// secure-storage push namespace, never in the database.
final class SecureWebPushStore implements WebPushStore {
  SecureWebPushStore(this._s);
  final SecureKeyStorage _s;

  static const _regKey = 'webpush_registration';
  static const _delKey = 'webpush_deliveries';

  Future<void> _lock = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final r = _lock.then((_) => op());
    _lock = r.then((_) {}, onError: (_) {});
    return r;
  }

  @override
  Future<WebPushRegistration?> registration() async {
    final raw = await _s.readPush(_regKey);
    if (raw == null) return null;
    try {
      return WebPushRegistration.parse(raw);
    } on WebPushCodeFailure {
      return null;
    }
  }

  @override
  Future<void> saveRegistration(WebPushRegistration r) => _s.writePush(_regKey, r.toCode());

  @override
  Future<void> clearRegistration() => _s.deletePush(_regKey);

  Future<Map<String, WebPushDelivery>> _read() async {
    final raw = await _s.readPush(_delKey);
    if (raw == null) return {};
    try {
      final j = jsonDecode(raw);
      if (j is! Map<String, Object?>) return {};
      final out = <String, WebPushDelivery>{};
      for (final e in j.entries) {
        final d = WebPushDelivery.fromJson(e.value);
        if (d != null) out[e.key] = d;
      }
      return out;
    } on FormatException {
      return {};
    }
  }

  @override
  Future<Map<String, WebPushDelivery>> deliveries() => _serial(_read);

  @override
  Future<void> setDelivery(String hostId, WebPushDelivery? d) => _serial(() async {
    final all = await _read();
    if (d == null) {
      all.remove(hostId);
    } else {
      all[hostId] = d;
    }
    await _s.writePush(_delKey, jsonEncode({for (final e in all.entries) e.key: e.value.toJson()}));
  });

  @override
  Future<void> clearDeliveries() => _serial(() => _s.deletePush(_delKey));
}
