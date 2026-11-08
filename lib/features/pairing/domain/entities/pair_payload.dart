/// QR pairing code, wire version 3 (TRD §6.3 step 4):
/// `openmosh://pair?v=3&i=<ip>&k=<hpk>&p=<port>&t=<tok>`.
///
/// Only what the phone needs to reach and authenticate the host: its tailnet IP,
/// the pairing port, its X25519 public key and a 16-byte one-time token. The
/// alias, SSH user, port and host key fingerprint arrive in the encrypted reply.
/// Every parameter appears exactly once; unknown ones are refused.
library;

import 'dart:typed_data';

import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/domain/tailnet.dart';

enum PairCodeError { malformed, unsupportedVersion, expired, notTailnet }

final class PairCodeFailure extends AppFailure {
  PairCodeFailure(this.reason) : super(_messages[reason]!);
  final PairCodeError reason;

  static const _messages = {
    PairCodeError.malformed: 'This is not a valid OpenMosh pairing code.',
    PairCodeError.unsupportedVersion:
        'This pairing code is from another OpenMosh version. Update the app and openmosh-hook.',
    PairCodeError.expired: 'This pairing code expired. Run `openmosh-hook pair` again.',
    PairCodeError.notTailnet: 'The host address is not a Tailscale address.',
  };
}

final _decimal = RegExp(r'^[1-9][0-9]{0,4}$');
const _keys = {'v', 'i', 'k', 'p', 't'};

final class PairPayload {
  const PairPayload({
    required this.ip,
    required this.hostPublicKey,
    required this.pairPort,
    required this.token,
  });

  static const version = 3;
  static const tokenLength = 16;

  final String ip;
  final Uint8List hostPublicKey;
  final int pairPort;
  final Uint8List token;

  static PairPayload parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'openmosh' || uri.host != 'pair') {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    final Map<String, List<String>> all;
    try {
      all = uri.queryParametersAll;
    } on FormatException {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    if (all.isEmpty) throw PairCodeFailure(PairCodeError.malformed);
    final v = all['v'];
    // v1 codes had only `d`; codes without `v` are from another version too.
    if (v == null) throw PairCodeFailure(PairCodeError.unsupportedVersion);
    if (v.length != 1) throw PairCodeFailure(PairCodeError.malformed);
    if (v.single != '$version') throw PairCodeFailure(PairCodeError.unsupportedVersion);
    if (all.keys.any((k) => !_keys.contains(k)) || all.values.any((v) => v.length != 1)) {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    final q = {for (final e in all.entries) e.key: e.value.single};

    final ip = q['i'];
    if (ip == null || ip.isEmpty || ip.length > 15) throw PairCodeFailure(PairCodeError.malformed);
    final hpk = _bytes(q, 'k', 32);
    final tok = _bytes(q, 't', tokenLength);
    final port = q['p'];
    if (port == null || !_decimal.hasMatch(port) || int.parse(port) > 65535) {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    if (!isTailnetIpv4(ip)) throw PairCodeFailure(PairCodeError.notTailnet);
    return PairPayload(ip: ip, hostPublicKey: hpk, pairPort: int.parse(port), token: tok);
  }

  static Uint8List _bytes(Map<String, String> q, String k, int len) {
    final v = q[k];
    if (v == null) throw PairCodeFailure(PairCodeError.malformed);
    try {
      final b = b64uDecode(v);
      if (b.length != len) throw PairCodeFailure(PairCodeError.malformed);
      return b;
    } on FormatException {
      throw PairCodeFailure(PairCodeError.malformed);
    }
  }
}
