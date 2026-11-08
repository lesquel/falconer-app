/// Tailscale address rules shared by pairing and endpoint checks.
library;

/// True for IPv4 addresses inside the Tailscale CGNAT range 100.64.0.0/10.
bool isTailnetIpv4(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return false;
  final octets = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255 || p.isEmpty || (p.length > 1 && p.startsWith('0'))) {
      return false;
    }
    octets.add(n);
  }
  return octets[0] == 100 && octets[1] >= 64 && octets[1] <= 127;
}

bool isTailnetHostName(String host) {
  final h = host.toLowerCase();
  return h.endsWith('.ts.net') || isTailnetIpv4(h);
}
