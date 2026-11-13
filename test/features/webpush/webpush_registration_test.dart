import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/webpush/domain/entities/webpush_registration.dart';
import 'package:openmosh/features/webpush/domain/entities/webpush_service.dart';
import 'package:openmosh/shared/domain/b64u.dart';

Map<String, Object?> body({int v = 1}) => {
  'v': v,
  'endpoint': 'https://web.push.apple.com/abc',
  'p256dh': b64uEncode(List.filled(65, 4)),
  'auth': b64uEncode(List.filled(16, 5)),
  'vapid_pub': b64uEncode(List.filled(65, 6)),
  'vapid_priv': b64uEncode(List.filled(32, 7)),
  'sub': 'mailto:me@example.com',
};

String enc(Map<String, Object?> m) => b64uEncode(utf8.encode(jsonEncode(m)));

void expectError(String code, WebPushCodeError e) => expect(
  () => WebPushRegistration.parse(code),
  throwsA(isA<WebPushCodeFailure>().having((f) => f.error, 'error', e)),
);

void main() {
  test('parses a good code, with or without padding', () {
    final r = WebPushRegistration.parse(enc(body()));
    expect(r.serviceHost, 'web.push.apple.com');
    expect(r.sub, 'mailto:me@example.com');
    final padded = base64Url.encode(utf8.encode(jsonEncode(body())));
    expect(WebPushRegistration.parse(' $padded ').hash, r.hash);
    expect(WebPushRegistration.parse(r.toCode()).hash, r.hash);
    expect(jsonDecode(utf8.decode(r.toStdin())), body());
  });

  test('rejects bad base64 and non-JSON', () {
    expectError('', WebPushCodeError.malformed);
    expectError('!!!!', WebPushCodeError.malformed);
    expectError('a', WebPushCodeError.malformed);
    expectError(b64uEncode(utf8.encode('not json')), WebPushCodeError.malformed);
    expectError(b64uEncode(utf8.encode('[1]')), WebPushCodeError.malformed);
  });

  test('unknown version', () {
    expectError(enc(body(v: 2)), WebPushCodeError.unsupportedVersion);
    expectError(enc({...body()}..remove('v')), WebPushCodeError.malformed);
  });

  test('missing or wrong-length fields', () {
    for (final k in ['endpoint', 'p256dh', 'auth', 'vapid_pub', 'vapid_priv', 'sub']) {
      expectError(enc({...body()}..remove(k)), WebPushCodeError.invalidField);
    }
    expectError(
      enc({...body(), 'p256dh': b64uEncode(List.filled(64, 1))}),
      WebPushCodeError.invalidField,
    );
    expectError(
      enc({...body(), 'auth': b64uEncode(List.filled(17, 1))}),
      WebPushCodeError.invalidField,
    );
    expectError(
      enc({...body(), 'vapid_priv': b64uEncode(List.filled(31, 1))}),
      WebPushCodeError.invalidField,
    );
    expectError(enc({...body(), 'vapid_pub': '+/+/'}), WebPushCodeError.invalidField);
  });

  test('endpoint must be https without credentials; sub must be https or mailto', () {
    for (final e in ['http://100.64.0.1/x', 'ftp://x/y', 'https://u:p@h/x', 'https:///x']) {
      expectError(enc({...body(), 'endpoint': e}), WebPushCodeError.invalidField);
    }
    for (final s in ['tel:123', 'mailto:', 'https://', 'x']) {
      expectError(enc({...body(), 'sub': s}), WebPushCodeError.invalidField);
    }
    expect(
      WebPushRegistration.parse(enc({...body(), 'sub': 'https://example.com/c'})).sub,
      'https://example.com/c',
    );
  });

  group('known push services', () {
    test('accepts FCM, Apple, Mozilla and WNS hosts over https', () {
      for (final u in [
        'https://fcm.googleapis.com/fcm/send/abc',
        'https://web.push.apple.com/abc',
        'https://api.push.apple.com/abc',
        'https://updates.push.services.mozilla.com/wpush/v2/abc',
        'https://autopush.push.services.mozilla.com/x',
        'https://db5.notify.windows.com/?token=x',
        'https://FCM.GoogleAPIs.com/x',
      ]) {
        expect(isKnownWebPushEndpoint(u), isTrue, reason: u);
      }
    });

    test('rejects lookalikes, other hosts and non-https', () {
      for (final u in [
        'https://fcm.googleapis.com.evil.com/x',
        'https://evilfcm.googleapis.com/x',
        'https://evil.com/fcm.googleapis.com',
        'https://fcm.googleapis.com@evil.com/x',
        'https://notpush.apple.com/x',
        'https://push.apple.com.evil.com/x',
        'https://notify.windows.com.evil.com/x',
        'https://push.services.mozilla.com.evil.com/x',
        'https://ntfy.sh/up1',
        'https://example.com/x',
        'http://fcm.googleapis.com/x',
        'http://web.push.apple.com/x',
        'ftp://fcm.googleapis.com/x',
        'fcm.googleapis.com/x',
        '',
      ]) {
        expect(isKnownWebPushEndpoint(u), isFalse, reason: u);
      }
    });

    test('registration with an unknown service host is rejected', () {
      for (final e in ['https://example.com/x', 'https://fcm.googleapis.com.evil.com/x']) {
        expectError(enc({...body(), 'endpoint': e}), WebPushCodeError.invalidField);
      }
      expect(
        WebPushRegistration.parse(
          enc({...body(), 'endpoint': 'https://fcm.googleapis.com/fcm/send/x'}),
        ).serviceHost,
        'fcm.googleapis.com',
      );
    });
  });
}
