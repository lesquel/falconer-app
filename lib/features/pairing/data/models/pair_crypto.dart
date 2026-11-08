/// Client side of the QR pairing exchange (TRD §6.3 steps 6 and 8).
library;

import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../../../shared/crypto/openmosh_crypto.dart' as c;
import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/display_text.dart';
import '../../../../shared/domain/failure.dart';
import '../../domain/entities/pairing_messages.dart';

export '../../domain/entities/pairing_messages.dart';

const _aad = 'openmosh/pair/v1';
final _fingerprint = RegExp(r'^SHA256:[A-Za-z0-9+/]{43}$');
final _user = RegExp(r'^[A-Za-z0-9._][A-Za-z0-9._-]{0,63}$');
const maxPairLineBytes = 16 * 1024;

final class SealedPairRequest {
  const SealedPairRequest(this.line, this.responseKey);

  /// One JSON line, without the trailing `\n`.
  final String line;
  final SecretKey responseKey;
}

abstract final class PairCrypto {
  /// [ephemeral] and [nonce] are injectable for the shared test vectors only.
  static Future<SealedPairRequest> sealRequest({
    required List<int> hostPublicKey,
    required List<int> token,
    required List<int> plaintext,
    SimpleKeyPair? ephemeral,
    List<int>? nonce,
  }) async {
    final eph = ephemeral ?? await c.newX25519KeyPair();
    final kReq = await c.deriveKey(
      private: eph,
      remotePublic: hostPublicKey,
      salt: token,
      info: 'openmosh/pair/v1/req',
    );
    final kResp = await c.deriveKey(
      private: eph,
      remotePublic: hostPublicKey,
      salt: token,
      info: 'openmosh/pair/v1/resp',
    );
    final n = nonce ?? c.randomBytes(c.nonceLength);
    final ct = await c.seal(key: kReq, nonce: n, plaintext: plaintext, aad: _aad);
    final line = jsonEncode({
      'v': 1,
      'e': b64uEncode(await c.x25519PublicBytes(eph)),
      'n': b64uEncode(n),
      'c': b64uEncode(ct),
    });
    if (utf8.encode(line).length + 1 > maxPairLineBytes) {
      throw const PairingFailure('Pairing request is too large.');
    }
    return SealedPairRequest(line, kResp);
  }

  static Future<PairResponse> openResponse(String line, SecretKey responseKey) async {
    const rejected = PairingFailure(
      'The host rejected pairing. Check that both devices use the same Tailscale account '
      'and that the code is still valid.',
    );
    const invalid = PairingFailure('The host sent an invalid pairing response.');
    final Object? json;
    try {
      json = jsonDecode(line);
    } on FormatException {
      throw invalid;
    }
    if (json is! Map<String, Object?> || json['v'] != 1) throw invalid;
    if (json.containsKey('err')) throw rejected;
    final n = json['n'];
    final ct = json['c'];
    if (n is! String || ct is! String) throw invalid;
    final List<int> pt;
    try {
      pt = await c.open(
        key: responseKey,
        nonce: b64uDecode(n),
        combined: b64uDecode(ct),
        aad: _aad,
      );
    } on FormatException {
      throw invalid;
    } on SecretBoxAuthenticationError {
      throw invalid;
    }
    final Object? body;
    try {
      body = jsonDecode(utf8.decode(pt));
    } on FormatException {
      throw invalid;
    }
    if (body is! Map<String, Object?>) throw invalid;
    final id = body['device_id'];
    final alias = body['alias'];
    final user = body['ssh_user'];
    final port = body['ssh_port'];
    final fp = body['ssh_fp'];
    if (!isWireId(id, max: 64) || alias is! String) throw invalid;
    if (user is! String || !_user.hasMatch(user)) throw invalid;
    if (port is! int || port < 1 || port > 65535) throw invalid;
    if (fp is! String || !_fingerprint.hasMatch(fp)) throw invalid;
    final cleanAlias = sanitizeLabel(alias);
    if (cleanAlias == null || cleanAlias.isEmpty) throw invalid;
    return PairResponse(
      deviceId: id as String,
      alias: cleanAlias,
      sshUser: user,
      sshPort: port,
      sshFingerprint: fp,
    );
  }
}
