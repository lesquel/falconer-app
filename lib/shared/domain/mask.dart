/// Masked forms of sensitive identifiers (addresses, keys, fingerprints),
/// shown until the user reveals them.
library;

const _dot = '•';
const _hidden = '••••';

final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');

/// `100.101.102.67` → `100.••.••.67`; `fd7a:115c::1` → `fd7a:••••:1`;
/// `box.tailnet.ts.net` → `bo••••et`. Short values are fully hidden.
String maskAddress(String address) {
  final a = address.trim();
  if (a.isEmpty) return a;
  final v4 = _ipv4.firstMatch(a);
  if (v4 != null) return '${v4[1]}.$_dot$_dot.$_dot$_dot.${v4[4]}';
  if (a.contains(':')) {
    final parts = a.split(':');
    return '${parts.first}:$_hidden:${parts.last}';
  }
  return _keepEnds(a, 2);
}

/// `SHA256:abcdef…yz` → `SHA256:ab••••••yz`.
String maskFingerprint(String fingerprint) {
  final i = fingerprint.indexOf(':');
  if (i < 0) return _keepEnds(fingerprint, 2, fill: '$_dot$_dot$_dot$_dot$_dot$_dot');
  final body = fingerprint.substring(i + 1);
  return '${fingerprint.substring(0, i + 1)}'
      '${_keepEnds(body, 2, fill: '$_dot$_dot$_dot$_dot$_dot$_dot')}';
}

/// `ssh-ed25519 AAAAC3Nz… comment` → `ssh-ed25519 AAAA••••…`.
String maskPublicKey(String publicKey) {
  final parts = publicKey.trim().split(RegExp(r'\s+'));
  if (parts.length < 2) return '$_hidden…';
  final blob = parts[1];
  final head = blob.length > 4 ? blob.substring(0, 4) : '';
  return '${parts.first} $head$_hidden…';
}

/// `user@address:port` with the address masked: `user@••••:22`.
String maskEndpoint(String user, String address, int port) => '$user@$_hidden:$port';

/// Keeps [n] characters at each end; values too short to keep anything are
/// fully hidden.
String _keepEnds(String s, int n, {String fill = _hidden}) {
  if (s.length <= n * 2 + 2) return fill;
  return '${s.substring(0, n)}$fill${s.substring(s.length - n)}';
}
