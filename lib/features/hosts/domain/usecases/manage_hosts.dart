import '../../../../shared/domain/failure.dart';
import '../../../../shared/ssh/domain/ssh_ports.dart';
import '../entities/host.dart';
import '../entities/host_draft.dart';
import '../repositories/host_repository.dart';

final _fp = RegExp(r'^SHA256:[A-Za-z0-9+/]{43}$');

/// Manual host flow: probe the host key, let the user confirm the
/// fingerprint, then save with that pin.
final class ManageHosts {
  const ManageHosts(this.repo, this.connector, {required this.newId, required this.now});

  final HostRepository repo;
  final SshConnector connector;
  final String Function() newId;
  final DateTime Function() now;

  Future<String> probe(HostDraft draft) {
    final d = draft.validated();
    return connector.probeFingerprint(d.address, d.port);
  }

  Future<Host> addConfirmed(
    HostDraft draft, {
    required String confirmedFingerprint,
    String? keyId,
  }) async {
    final d = draft.validated();
    if (!_fp.hasMatch(confirmedFingerprint)) {
      throw const ValidationFailure('Invalid host key fingerprint.');
    }
    final host = Host(
      id: newId(),
      alias: d.alias,
      address: d.address,
      port: d.port,
      user: d.user,
      fingerprint: confirmedFingerprint,
      pairedVia: PairedVia.manual,
      createdAt: now(),
      keyId: keyId,
    );
    await repo.save(host);
    return host;
  }

  /// Editing never changes the pinned fingerprint; re-adding is required.
  Future<Host> edit(Host host, HostDraft draft, {String? keyId}) async {
    final d = draft.validated();
    if (d.address != host.address || d.port != host.port) {
      throw const ValidationFailure(
        'Changing address or port needs a new host key check. Add the host again.',
      );
    }
    final updated = host.copyWith(alias: d.alias, user: d.user, keyId: keyId);
    await repo.save(updated);
    return updated;
  }

  Future<void> delete(String id) => repo.delete(id);
}
