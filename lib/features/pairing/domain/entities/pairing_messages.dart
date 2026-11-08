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

final class PairResponse {
  const PairResponse({required this.deviceId, required this.alias});
  final String deviceId;
  final String alias;
}
