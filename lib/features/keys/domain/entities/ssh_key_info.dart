/// Public metadata of an SSH key. The private half never leaves the vault
/// except as an argument to an SSH connect call.
library;

final class SshKeyInfo {
  const SshKeyInfo({
    required this.id,
    required this.label,
    required this.publicKey,
    required this.fingerprint,
    required this.imported,
    required this.createdAt,
  });

  static const deviceKeyId = 'device';

  final String id;
  final String label;
  final String publicKey;
  final String fingerprint;
  final bool imported;
  final DateTime createdAt;
}
