/// Rust-core adapter for [SshConnector]. Maps `<code>: …` errors from the
/// core into domain failures.
library;

import 'dart:typed_data';

import 'package:flutter_rust_bridge/flutter_rust_bridge.dart';

import '../../../bridge/api/ssh.dart' as rs;
import '../../../domain/failure.dart';
import '../../domain/ssh_ports.dart';

AppFailure mapCoreError(Object e) {
  final msg = e is AnyhowException ? e.message : e.toString();
  final code = msg.split(':').first.trim();
  switch (code) {
    case 'host_key_mismatch':
      final m = RegExp(r'expected (\S*) got (\S*)').firstMatch(msg);
      return HostKeyMismatchFailure(expected: m?.group(1) ?? '', actual: m?.group(2) ?? '');
    case 'auth_failed':
      return const AuthFailure();
    case 'timeout':
      return const ConnectionFailure('The host did not answer in time.');
    case 'too_large':
      return const ValidationFailure('The data is too large.');
    case 'invalid_key':
      return const ValidationFailure('That is not a usable ssh-ed25519 private key.');
    case 'sftp_failed':
      return const ConnectionFailure('Upload failed.');
    default:
      return const ConnectionFailure();
  }
}

Future<T> _guard<T>(Future<T> Function() f) async {
  try {
    return await f();
  } on AppFailure {
    rethrow;
  } catch (e) {
    throw mapCoreError(e);
  }
}

final class RustSshConnector implements SshConnector {
  const RustSshConnector();

  @override
  Future<SshConnection> connect(SshEndpoint e, {required String privateKeyOpenssh}) =>
      _guard(() async {
        final client = await rs.SshClient.connect(
          host: e.host,
          port: e.port,
          user: e.user,
          pinnedFingerprint: e.pinnedFingerprint,
          privateOpenssh: privateKeyOpenssh,
        );
        return _RustConnection(client);
      });

  @override
  Future<String> probeFingerprint(String host, int port) =>
      _guard(() => rs.probeHostFingerprint(host: host, port: port));
}

final class _RustConnection implements SshConnection {
  _RustConnection(this._client);
  final rs.SshClient _client;

  @override
  Future<ExecOutput> exec(String command, {List<int>? stdin}) => _guard(() async {
    final r = await _client.exec(
      command: command,
      stdin: stdin == null ? null : Uint8List.fromList(stdin),
    );
    return ExecOutput(exitCode: r.exitCode, stdout: r.stdout, stderr: r.stderr);
  });

  @override
  Future<ShellChannel> openShell({required int cols, required int rows}) => _guard(() async {
    final s = await _client.openShell(cols: cols, rows: rows);
    return _RustShell(s, s.output());
  });

  @override
  Future<String> upload(String localPath, String remoteName) =>
      _guard(() => _client.upload(localPath: localPath, remoteName: remoteName));

  @override
  bool get isClosed => _client.isClosed();

  @override
  String? get closeReason => _client.closeReason();

  @override
  Future<void> close() => _client.disconnect();
}

final class _RustShell implements ShellChannel {
  _RustShell(this._s, this.output);
  final rs.ShellSession _s;

  @override
  final Stream<Uint8List> output;

  @override
  Future<void> write(List<int> data) => _guard(() => _s.write(data: data));

  @override
  Future<void> resize(int cols, int rows) => _guard(() => _s.resize(cols: cols, rows: rows));

  @override
  Future<void> close() => _s.close();
}
