/// Runs `openmosh-hook` commands over an exec channel and decodes the
/// JSON envelope.
library;

import 'dart:convert';

import '../../domain/failure.dart';
import '../../ssh/domain/ssh_ports.dart';
import 'hook_command.dart';
import 'hook_envelope.dart';

final class HookClient {
  const HookClient();

  Future<Object?> call(
    SshConnection conn,
    String hookPath,
    HookCommand cmd, {
    List<int>? stdin,
  }) async {
    final out = await conn.exec(cmd.toShell(hookPath), stdin: stdin);
    if (out.stdout.isEmpty && out.exitCode == 127) {
      throw const HookFailure('hook_missing', 'openmosh-hook is not installed on this host.');
    }
    if (!cmd.argv.contains('--json')) {
      if (out.exitCode != 0) {
        throw const HookFailure('error', 'Host command failed.');
      }
      return null;
    }
    return parseHookEnvelope(out.stdout);
  }

  /// Runs [HookCommand.resolvePathScript]; returns an absolute path.
  Future<String> resolvePath(SshConnection conn) async {
    final out = await conn.exec(HookCommand.resolvePathScript);
    final path = utf8.decode(out.stdout, allowMalformed: true).trim();
    if (!path.startsWith('/') || path.contains(RegExp(r'[\x00-\x1f\x7f]')) || path.length > 512) {
      throw const HookFailure('hook_missing', 'openmosh-hook is not installed on this host.');
    }
    return path;
  }
}
