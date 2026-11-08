/// SSH ports shared by every feature that talks to a host. The only adapter
/// is `data/datasources/ssh_bridge.dart` (Rust core via flutter_rust_bridge).
library;

import 'dart:typed_data';

final class SshEndpoint {
  const SshEndpoint({
    required this.host,
    required this.port,
    required this.user,
    required this.pinnedFingerprint,
  });

  final String host;
  final int port;
  final String user;

  /// `SHA256:` fingerprint; a mismatch aborts the handshake.
  final String pinnedFingerprint;
}

final class ExecOutput {
  const ExecOutput({required this.exitCode, required this.stdout, required this.stderr});
  final int? exitCode;
  final Uint8List stdout;
  final Uint8List stderr;
}

abstract interface class ShellChannel {
  /// Batched output; completes when the remote side closes.
  Stream<Uint8List> get output;
  Future<void> write(List<int> data);
  Future<void> resize(int cols, int rows);
  Future<void> close();
}

abstract interface class SshConnection {
  Future<ExecOutput> exec(String command, {List<int>? stdin});
  Future<ShellChannel> openShell({required int cols, required int rows});

  /// Uploads into `~/.openmosh/uploads/`; returns the remote absolute path.
  Future<String> upload(String localPath, String remoteName);
  bool get isClosed;
  Future<void> close();
}

abstract interface class SshConnector {
  Future<SshConnection> connect(SshEndpoint endpoint, {required String privateKeyOpenssh});

  /// Reads the server host key fingerprint without authenticating.
  Future<String> probeFingerprint(String host, int port);
}
