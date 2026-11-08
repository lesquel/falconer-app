/// IPv4 and Tailscale address rules shared by pairing, host and endpoint checks.
library;

final _octet = RegExp(r'^(0|[1-9][0-9]{0,2})$');

/// Parses a strict dotted quad: four decimal octets 0–255, ASCII digits only,
/// no whitespace, sign, hex or leading zeros. Returns null otherwise.
List<int>? parseIpv4(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  final octets = <int>[];
  for (final p in parts) {
    if (!_octet.hasMatch(p)) return null;
    final n = int.parse(p);
    if (n > 255) return null;
    octets.add(n);
  }
  return octets;
}

bool isIpv4Literal(String ip) => parseIpv4(ip) != null;

/// True for IPv4 addresses inside the Tailscale CGNAT range 100.64.0.0/10.
bool isTailnetIpv4(String ip) {
  final o = parseIpv4(ip);
  return o != null && o[0] == 100 && o[1] >= 64 && o[1] <= 127;
}

bool isTailnetHostName(String host) {
  final h = host.toLowerCase();
  return h.endsWith('.ts.net') || isTailnetIpv4(h);
}
