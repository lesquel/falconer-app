/// User input for adding or editing a host, with validation.
library;

import '../../../../shared/domain/failure.dart';
import '../../../../shared/domain/tailnet.dart';

final _user = RegExp(r'^[A-Za-z0-9._][A-Za-z0-9._-]{0,63}$');
final _hostname = RegExp(r'^[A-Za-z0-9]([A-Za-z0-9.-]{0,251}[A-Za-z0-9])?$');
final _ipv6 = RegExp(r'^[0-9A-Fa-f:]{2,39}$');
final _numericDotted = RegExp(r'^[0-9.]+$');

final class HostDraft {
  const HostDraft({
    required this.alias,
    required this.address,
    required this.port,
    required this.user,
  });

  final String alias;
  final String address;
  final int port;
  final String user;

  /// Throws [ValidationFailure] with a user-facing message.
  HostDraft validated() {
    final a = alias.trim();
    final h = address.trim();
    final u = user.trim();
    if (a.isEmpty || a.length > 64) throw const ValidationFailure('Name must be 1–64 characters.');
    final looksIpv4 = _numericDotted.hasMatch(h);
    if (looksIpv4 ? !isIpv4Literal(h) : !_hostname.hasMatch(h) && !_ipv6.hasMatch(h)) {
      throw const ValidationFailure('Enter a hostname or IP address.');
    }
    if (port < 1 || port > 65535) throw const ValidationFailure('Port must be 1–65535.');
    if (!_user.hasMatch(u)) throw const ValidationFailure('Enter a valid user name.');
    return HostDraft(alias: a, address: h, port: port, user: u);
  }
}
