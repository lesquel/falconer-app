/// QR pairing code (`openmosh://pair?d=<b64u(JSON)>`, TRD §6.3 step 4).
library;

import 'dart:convert';
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

final _fingerprint = RegExp(r'^SHA256:[A-Za-z0-9+/]{43}$');
final _user = RegExp(r'^[A-Za-z0-9._][A-Za-z0-9._-]{0,63}$');

final class PairPayload {
  const PairPayload({
    required this.alias,
    required this.address,
    required this.ip,
    required this.sshPort,
    required this.sshUser,
    required this.sshFingerprint,
    required this.hostPublicKey,
    required this.pairPort,
    required this.token,
    required this.expiresAt,
  });

  static const version = 1;

  /// Codes live 5 minutes; anything claiming to live longer than a day is not ours.
  static const maxLifetimeSecs = 86400;

  final String alias;
  final String address;
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
    final d = uri.queryParameters['d'];
    if (d == null || d.isEmpty) throw PairCodeFailure(PairCodeError.malformed);
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(b64uDecode(d)));
    } on FormatException {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    if (json is! Map<String, Object?>) throw PairCodeFailure(PairCodeError.malformed);
    if (json['v'] != version) throw PairCodeFailure(PairCodeError.unsupportedVersion);

    final alias = sanitizeLabel(_str(json, 'alias', max: 64));
    if (alias == null || alias.isEmpty) throw PairCodeFailure(PairCodeError.malformed);
    final address = _str(json, 'addr', max: 253);
    final ip = _str(json, 'ip', max: 15);
    final sshUser = _str(json, 'ssh_user', max: 64);
    if (!_user.hasMatch(sshUser)) throw PairCodeFailure(PairCodeError.malformed);
    final fp = _str(json, 'ssh_fp', max: 64);
    if (!_fingerprint.hasMatch(fp)) throw PairCodeFailure(PairCodeError.malformed);
    final hpk = _bytes(json, 'hpk', 32);
    final tok = _bytes(json, 'tok', 32);
    final sshPort = _port(json, 'ssh_port');
    final pairPort = _port(json, 'port');
    final exp = json['exp'];
    final nowSecs = now.millisecondsSinceEpoch ~/ 1000;
    if (exp is! int || exp <= 0 || exp > nowSecs + maxLifetimeSecs) {
      throw PairCodeFailure(PairCodeError.malformed);
    }

    if (!isTailnetIpv4(ip)) throw PairCodeFailure(PairCodeError.notTailnet);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
    if (!now.isBefore(expiresAt)) throw PairCodeFailure(PairCodeError.expired);

    return PairPayload(
      alias: alias,
      address: address,
      ip: ip,
      sshPort: sshPort,
      sshUser: sshUser,
      sshFingerprint: fp,
      hostPublicKey: hpk,
      pairPort: pairPort,
      token: tok,
      expiresAt: expiresAt,
    );
  }

  static String _str(Map<String, Object?> j, String k, {required int max}) {
    final v = j[k];
    if (v is! String || v.isEmpty || v.length > max || v.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
      throw PairCodeFailure(PairCodeError.malformed);
    }
    return v;
  }

  static Uint8List _bytes(Map<String, Object?> j, String k, int len) {
    final v = j[k];
    if (v is! String) throw PairCodeFailure(PairCodeError.malformed);
    try {
      final b = b64uDecode(v);
      if (b.length != len) throw PairCodeFailure(PairCodeError.malformed);
      return b;
    } on FormatException {
      throw PairCodeFailure(PairCodeError.malformed);
    }
  }

  static int _port(Map<String, Object?> j, String k) {
    final v = j[k];
    if (v is! int || v < 1 || v > 65535) throw PairCodeFailure(PairCodeError.malformed);
    return v;
  }
}
