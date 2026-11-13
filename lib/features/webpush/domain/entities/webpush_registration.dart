/// A Web Push registration made by the OpenMosh notifications PWA: the
/// browser's push subscription plus the VAPID key pair the PWA generated.
/// It holds a private key, so it is never logged and only lives in secure
/// storage.
///
/// Code format: base64url (padding optional) of the UTF-8 JSON
/// `{"v":1,"endpoint","p256dh","auth","vapid_pub","vapid_priv","sub"}`.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/failure.dart';
import '../../../inbox/domain/entities/push_endpoint.dart';
import 'webpush_service.dart';

enum WebPushCodeError { malformed, unsupportedVersion, invalidField }

final class WebPushCodeFailure extends AppFailure {
  const WebPushCodeFailure(this.error, super.message);
  final WebPushCodeError error;

  static const malformedMessage = 'This is not a valid web notifications code.';
  static const versionMessage =
      'This web notifications code is from another OpenMosh version. Update the app.';

  factory WebPushCodeFailure.of(WebPushCodeError e) => WebPushCodeFailure(
    e,
    e == WebPushCodeError.unsupportedVersion ? versionMessage : malformedMessage,
  );
}

final class WebPushRegistration {
  const WebPushRegistration._({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
    required this.vapidPub,
    required this.vapidPriv,
    required this.sub,
  });

  static const maxCodeLength = 4096;

  final String endpoint;
  final String p256dh;
  final String auth;
  final String vapidPub;
  final String vapidPriv;
  final String sub;

  /// Parses and validates a pasted or linked code. Throws [WebPushCodeFailure].
  factory WebPushRegistration.parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text.length > maxCodeLength) {
      throw WebPushCodeFailure.of(WebPushCodeError.malformed);
    }
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(b64uDecode(text.replaceAll(RegExp(r'=+$'), ''))));
    } on FormatException {
      throw WebPushCodeFailure.of(WebPushCodeError.malformed);
    }
    if (json is! Map<String, Object?>) throw WebPushCodeFailure.of(WebPushCodeError.malformed);
    final map = json;
    if (map['v'] != 1) {
      throw WebPushCodeFailure.of(
        map['v'] is int ? WebPushCodeError.unsupportedVersion : WebPushCodeError.malformed,
      );
    }
    String bytes(String key, int length) {
      final v = map[key];
      if (v is! String) throw WebPushCodeFailure.of(WebPushCodeError.invalidField);
      final clean = v.replaceAll(RegExp(r'=+$'), '');
      try {
        if (b64uDecode(clean).length != length) throw const FormatException();
      } on FormatException {
        throw WebPushCodeFailure.of(WebPushCodeError.invalidField);
      }
      return clean;
    }

    final endpoint = map['endpoint'];
    final sub = map['sub'];
    if (endpoint is! String ||
        endpoint.length > 2048 ||
        !endpoint.startsWith('https://') ||
        !isAllowedPushEndpoint(endpoint) ||
        !isKnownWebPushEndpoint(endpoint)) {
      throw WebPushCodeFailure.of(WebPushCodeError.invalidField);
    }
    if (sub is! String ||
        sub.length > 256 ||
        !(sub.startsWith('https://') && sub.length > 8 ||
            sub.startsWith('mailto:') && sub.length > 7)) {
      throw WebPushCodeFailure.of(WebPushCodeError.invalidField);
    }
    return WebPushRegistration._(
      endpoint: endpoint,
      p256dh: bytes('p256dh', 65),
      auth: bytes('auth', 16),
      vapidPub: bytes('vapid_pub', 65),
      vapidPriv: bytes('vapid_priv', 32),
      sub: sub,
    );
  }

  /// The JSON object the hook receives on stdin.
  Map<String, Object?> toJson() => {
    'v': 1,
    'endpoint': endpoint,
    'p256dh': p256dh,
    'auth': auth,
    'vapid_pub': vapidPub,
    'vapid_priv': vapidPriv,
    'sub': sub,
  };

  List<int> toStdin() => utf8.encode(jsonEncode(toJson()));

  /// Canonical code; what secure storage keeps.
  String toCode() => b64uEncode(toStdin());

  /// Identifies this registration (never reveals it) to track delivery.
  String get hash => sha256.convert(toStdin()).toString();

  /// Only the push service, e.g. `web.push.apple.com`.
  String get serviceHost => Uri.parse(endpoint).host;
}
