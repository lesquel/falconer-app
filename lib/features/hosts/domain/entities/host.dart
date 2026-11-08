/// A saved host. The pinned fingerprint is mandatory: a host cannot exist
/// without a confirmed host key (from the QR code or explicit confirmation).
library;

enum PairedVia { qr, ssh, manual }

final class Host {
  const Host({
    required this.id,
    required this.alias,
    required this.address,
    required this.port,
    required this.user,
    required this.fingerprint,
    required this.pairedVia,
    required this.createdAt,
    this.keyId,
    this.hookPath,
    this.deviceId,
    this.hostPushKey,
    this.endpointSent,
    this.lastAttach,
  });

  final String id;
  final String alias;
  final String address;
  final int port;
  final String user;
  final String fingerprint;
  final PairedVia pairedVia;
  final DateTime createdAt;

  /// SSH key used for this host; `null` means the device key.
  final String? keyId;
  final String? hookPath;

  /// Assigned by the host at pairing; also the push `kid`.
  final String? deviceId;

  /// Host X25519 public key (b64u) used to decrypt pushes.
  final String? hostPushKey;
  final String? endpointSent;

  /// Command that re-attaches the last Herdr/tmux session.
  final String? lastAttach;

  /// Registered as a device on the host (QR or SSH pairing).
  bool get paired => deviceId != null && hostPushKey != null;

  /// Paired with a push endpoint. An empty [endpointSent] means the phone
  /// paired without one (no push distributor answered).
  bool get pushEnabled => paired && endpointSent != '';

  Host copyWith({
    String? alias,
    String? address,
    int? port,
    String? user,
    String? keyId,
    String? hookPath,
    String? deviceId,
    String? hostPushKey,
    String? endpointSent,
    String? lastAttach,
    PairedVia? pairedVia,
  }) => Host(
    id: id,
    alias: alias ?? this.alias,
    address: address ?? this.address,
    port: port ?? this.port,
    user: user ?? this.user,
    fingerprint: fingerprint,
    pairedVia: pairedVia ?? this.pairedVia,
    createdAt: createdAt,
    keyId: keyId ?? this.keyId,
    hookPath: hookPath ?? this.hookPath,
    deviceId: deviceId ?? this.deviceId,
    hostPushKey: hostPushKey ?? this.hostPushKey,
    endpointSent: endpointSent ?? this.endpointSent,
    lastAttach: lastAttach ?? this.lastAttach,
  );
}
