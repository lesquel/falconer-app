import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../../domain/entities/herdr_action.dart';
import '../../domain/entities/herdr_snapshot.dart';
import '../../domain/repositories/herdr_repository.dart';

/// Messages of the failures the navigator shows (translated in l10n).
const herdrInvalid = 'Herdr no longer has that item. The list was refreshed.';
const herdrNotRunning = 'Herdr is not running on this computer.';
const herdrRefused = 'Herdr refused the request.';
const herdrHookOutdated = 'Update openmosh-hook on this computer to use the Herdr navigator.';

/// [HerdrRepository] over `openmosh-hook herdr … --json` on the host's SSH
/// connection.
final class HookHerdrRepository implements HerdrRepository {
  HookHerdrRepository(this.connections);
  final HostConnections connections;

  /// Hosts whose hook was seen speaking `herdr` ≥ 1 (a "no" is asked again,
  /// so updating the hook needs no restart).
  final Set<String> _supported = {};

  @override
  Future<bool> supportsHerdr(String hostId) async {
    if (_supported.contains(hostId)) return true;
    try {
      final data = await connections.runHook(hostId, HookCommand.version());
      final protocol = data is Map<String, Object?> ? data['protocol'] : null;
      final herdr = protocol is Map<String, Object?> ? protocol['herdr'] : null;
      final ok = herdr is int && herdr >= 1;
      if (ok) _supported.add(hostId);
      return ok;
    } on AppFailure {
      return false;
    }
  }

  @override
  Future<Polled<HerdrSnapshot>> snapshot(
    String hostId, {
    String? session,
    String? since,
    int waitMs = 0,
  }) async {
    final cmd = HookCommand.herdrSnapshot(session: session, since: since, waitMs: waitMs);
    return Polled.fromJson(await _run(hostId, cmd), HerdrSnapshot.fromJson);
  }

  @override
  Future<Polled<PaneScreen>> read(
    String hostId,
    String paneId, {
    String? session,
    String? since,
    int waitMs = 0,
    int? lines,
  }) async {
    final cmd = HookCommand.herdrRead(
      paneId,
      session: session,
      since: since,
      waitMs: waitMs,
      lines: lines,
    );
    return Polled.fromJson(await _run(hostId, cmd), PaneScreen.fromJson);
  }

  @override
  Future<String?> act(String hostId, HerdrAction action, {String? session}) async {
    final data = await _run(
      hostId,
      HookCommand.herdrAction(session: session),
      stdin: action.toBytes(),
    );
    final id = data is Map<String, Object?> ? data['id'] : null;
    return id is String && id.length <= 64 ? id : null;
  }

  Future<Object?> _run(String hostId, HookCommand cmd, {List<int>? stdin}) async {
    try {
      return await connections.runHook(hostId, cmd, stdin: stdin);
    } on HookFailure catch (e) {
      throw switch (e.code) {
        'invalid_request' => const HookFailure('invalid_request', herdrInvalid),
        'runtime_unavailable' => const HookFailure('runtime_unavailable', herdrNotRunning),
        'runtime_error' => const HookFailure('runtime_error', herdrRefused),
        // An older hook rejects `herdr` (clap usage on stderr, no JSON).
        'protocol' || 'unknown_command' => const HookFailure('hook_outdated', herdrHookOutdated),
        _ => e,
      };
    }
  }
}
