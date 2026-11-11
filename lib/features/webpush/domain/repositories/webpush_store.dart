import '../entities/webpush_delivery.dart';
import '../entities/webpush_registration.dart';

/// Secret storage for the registration (it holds a private key) and the
/// per-host delivery record.
abstract interface class WebPushStore {
  Future<WebPushRegistration?> registration();
  Future<void> saveRegistration(WebPushRegistration r);
  Future<void> clearRegistration();

  Future<Map<String, WebPushDelivery>> deliveries();

  /// Sets or, with `null`, removes one host's record (serialized writes).
  Future<void> setDelivery(String hostId, WebPushDelivery? d);
  Future<void> clearDeliveries();
}
