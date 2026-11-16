import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../entities/agent_usage.dart';

/// Message of the failure raised when the host's hook predates `usage`.
const hookOutdatedForUsage = 'Update falconer-hook on this computer to see usage.';

/// Loads token usage per agent through `falconer-hook usage --json`.
final class LoadAgentUsage {
  const LoadAgentUsage(this.connections);
  final HostConnections connections;

  Future<UsageReport> call(String hostId, {int days = 7}) async {
    final cmd = HookCommand.usage(days: days);
    try {
      return UsageReport.fromJson(await connections.runHook(hostId, cmd));
    } on HookFailure catch (e) {
      // An older hook rejects the unknown subcommand: clap prints to stderr
      // (no JSON on stdout, so `protocol`), or a newer parser says so.
      if (e.code == 'protocol' || e.code == 'unknown_command') {
        throw const HookFailure('hook_outdated', hookOutdatedForUsage);
      }
      rethrow;
    }
  }
}
