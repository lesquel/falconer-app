/// QR pairing code, wire version 2 (TRD §6.3 step 4):
/// `openmosh://pair?v=2&n=<alias>&i=<ip>&s=<ssh_port>&u=<ssh_user>&f=<fp>&k=<hpk>&p=<port>&t=<tok>&e=<exp>`.
///
/// `f` is the SHA256 host key fingerprint without its `SHA256:` prefix, in the
/// b64url alphabet. Every parameter appears exactly once; unknown ones are refused.
library;

import 'dart:typed_data';

import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/display_text.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/domain/tailnet.dart';

enum PairCodeError { malformed, unsupportedVersion, expired, notTailnet }

final class PairCodeFailure extends AppFailure {
  PairCodeFailure(this.reason) : super(_messages[reason]!);
  final PairCodeError reason;

  static const _messages = {
    PairCodeError.malformed: 'This is not a valid OpenMosh pairing code.',
    PairCodeError.unsupportedVersion: 'This pairing code needs a newer app version.',
    PairCodeError.expired: 'This pairing code expired. Run `openmosh-hook pair` again.',
    PairCodeError.notTailnet: 'The host address is not a Tailscale address.',
  };
}

final _fingerprint = RegExp(r'^[A-Za-z0-9_-]{43}$');
final _decimal = RegExp(r'^[1-9][0-9]{0,15}$');
const _keys = {'v', 'n', 'i', 's', 'u', 'f', 'k', 'p', 't', 'e'};
final _user = RegExp(r'^[A-Za-z0-9._][A-Za-z0-9._-]{0,63}$');

final class PairPayload {
  const PairPayload({
    required this.alias,
    required this.ip,
    required this.sshPort,
    required this.sshUser,
    required this.sshFingerprint,
    required this.hostPublicKey,
    required this.pairPort,
    required this.token,
    required this.expiresAt,
  });

  static const version = 2;

  /// Codes live 5 minutes; anything claiming to live longer than a day is not ours.
  static const maxLifetimeSecs = 86400;

  final String alias;
  final String ip;
  final int sshPort;
  final String sshUser;
  final String sshFingerprint;
  final Uint8List hostPublicKey;
  final int pairPort;
  final Uint8List token;
  final DateTime expiresAt;

  static PairPayload parse(String raw, {required DateTime now}) {
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
    if (all['v']?.length != 1) {
      // v1 codes carried the whole offer in `d` and had no `v` parameter.
      if (all.containsKey('d') || !all.containsKey('v')) {
        throw PairCodeFailure(PairCodeError.unsupportedVersion);
      }
      throw PairCodeFailure(PairCodeError.malformed);
    }
    if (all['v']!.single != '$version') throw PairCodeFailure(PairCodeError.unsupportedVersion);
    if (all.keys.any((k) => !_keys.contains(k)) || all.values.any((v) => v.length != 1)) {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    final q = {for (final e in all.entries) e.key: e.value.single};

    final alias = sanitizeLabel(_str(q, 'n', max: 64));
    if (alias == null || alias.isEmpty) throw PairCodeFailure(PairCodeError.malformed);
    final ip = _str(q, 'i', max: 15);
    final sshUser = _str(q, 'u', max: 64);
    if (!_user.hasMatch(sshUser)) throw PairCodeFailure(PairCodeError.malformed);
    final fp = _str(q, 'f', max: 43);
    if (!_fingerprint.hasMatch(fp)) throw PairCodeFailure(PairCodeError.malformed);
    final hpk = _bytes(q, 'k', 32);
    final tok = _bytes(q, 't', 32);
    final sshPort = _port(q, 's');
    final pairPort = _port(q, 'p');
    final exp = _int(q, 'e');
    final nowSecs = now.millisecondsSinceEpoch ~/ 1000;
    if (exp > nowSecs + maxLifetimeSecs) throw PairCodeFailure(PairCodeError.malformed);

    if (!isTailnetIpv4(ip)) throw PairCodeFailure(PairCodeError.notTailnet);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    if (!now.isBefore(expiresAt)) throw PairCodeFailure(PairCodeError.expired);

    return PairPayload(
      alias: alias,
      ip: ip,
      sshPort: sshPort,
      sshUser: sshUser,
      sshFingerprint: 'SHA256:${fp.replaceAll('-', '+').replaceAll('_', '/')}',
      hostPublicKey: hpk,
      pairPort: pairPort,
      token: tok,
      expiresAt: expiresAt,
    );
  }

  static String _str(Map<String, String> q, String k, {required int max}) {
    final v = q[k];
    if (v == null || v.isEmpty || v.length > max || v.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    return v;
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

  /// Positive decimal integer without sign, spaces or leading zeros.
  static int _int(Map<String, String> q, String k) {
    final v = q[k];
    if (v == null || !_decimal.hasMatch(v)) throw PairCodeFailure(PairCodeError.malformed);
    return int.parse(v);
  }

  static int _port(Map<String, String> q, String k) {
    final v = _int(q, k);
    if (v > 65535) throw PairCodeFailure(PairCodeError.malformed);
    return v;
  }
}
