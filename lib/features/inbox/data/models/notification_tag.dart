/// HMAC-SHA256 tag that binds a notification payload to this install.
///
/// The launcher activity is exported, so any app can start it with a
/// `SELECT_NOTIFICATION` intent carrying its own `payload` and `actionId`.
/// Only payloads the app signed with its per-install key are routed; the
/// key never leaves the device's secure storage.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import '../../../keys/data/datasources/secure_key_storage.dart';

final class NotificationTagger {
  NotificationTagger(List<int> key) : _hmac = Hmac(sha256, List.unmodifiable(key));

  final Hmac _hmac;

  /// Separates the route from its tag. Never in a route: ids are encoded
  /// path segments.
  static const separator = '|';

  /// Push namespace: readable without a prompt by the background isolate
  /// that posts notifications.
  static const storageKey = 'notification_tag_key';
  static const keyLength = 32;

  /// Loads the per-install key, creating it on first use.
  static Future<NotificationTagger> load(SecureKeyStorage storage) async {
    final stored = await storage.readPush(storageKey);
    final key = stored == null ? null : _decode(stored);
    if (key != null && key.length == keyLength) return NotificationTagger(key);
    final rng = Random.secure();
    final fresh = List<int>.generate(keyLength, (_) => rng.nextInt(256));
    await storage.writePush(storageKey, base64Url.encode(fresh));
    return NotificationTagger(fresh);
  }

  static List<int>? _decode(String v) {
    try {
      return base64Url.decode(v);
    } on FormatException {
      return null;
    }
  }

  String _tag(String route) => base64Url.encode(_hmac.convert(utf8.encode(route)).bytes);

  /// `route|tag`.
  String sign(String route) => '$route$separator${_tag(route)}';

  /// The route of a payload this install signed, or null when the tag is
  /// missing or wrong. Compared in constant time.
  String? verify(String payload) {
    final i = payload.lastIndexOf(separator);
    if (i < 0) return null;
    final route = payload.substring(0, i);
    return _equal(payload.substring(i + 1), _tag(route)) ? route : null;
  }

  static bool _equal(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
