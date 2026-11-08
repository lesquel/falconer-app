/// Plaintext messages of the QR pairing exchange (TRD §6.3).
library;

import 'dart:convert';

import '../../../../shared/domain/b64u.dart';

final class PairRequestBody {
  const PairRequestBody({
    required this.token,
    required this.name,
    required this.sshPublicKey,
    required this.pushPublicKey,
    required this.endpoint,
  });

  final List<int> token;
  final String name;
  final String sshPublicKey;
  final List<int> pushPublicKey;
  final String endpoint;

  List<int> toJsonBytes() => utf8.encode(
    jsonEncode({
      'tok': b64uEncode(token),
      'name': name,
      'ssh_pub': sshPublicKey,
      'ppk': b64uEncode(pushPublicKey),
      'endpoint': endpoint,
    }),
  );
}

/// Decrypted host reply. It is authenticated by the token and the host key from
/// the QR, so its SSH details are pinned as received.
final class PairResponse {
  const PairResponse({
    required this.deviceId,
    required this.alias,
    required this.sshUser,
    required this.sshPort,
    required this.sshFingerprint,
  });
  final String deviceId;
  final String alias;
  final String sshUser;
  final int sshPort;
  final String sshFingerprint;
}
