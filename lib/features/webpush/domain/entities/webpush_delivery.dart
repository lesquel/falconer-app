library;

/// What is known about one host and the current registration.
enum WebPushDeliveryStatus {
  /// The host accepted the registration with [WebPushDelivery.hash].
  delivered,

  /// The host's `openmosh-hook` does not know `set-webpush`.
  hookTooOld,

  /// "Turn off" could not reach the host yet; `clear-webpush` is owed.
  clearPending,
}

final class WebPushDelivery {
  const WebPushDelivery(this.status, this.hash);
  final WebPushDeliveryStatus status;
  final String hash;

  Map<String, Object?> toJson() => {'s': status.name, 'h': hash};

  static WebPushDelivery? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final s = WebPushDeliveryStatus.values.where((v) => v.name == json['s']).firstOrNull;
    final h = json['h'];
    return s == null || h is! String ? null : WebPushDelivery(s, h);
  }
}

/// Outcome of syncing one host.
enum WebPushHostResult { delivered, alreadyDelivered, cleared, hookTooOld, failed, skipped }
