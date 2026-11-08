/// Rust-core adapter for Ed25519 key generation/import.
library;

import '../../../../shared/bridge/api/keys.dart' as rs;
import '../../../../shared/domain/failure.dart';

final class KeyMaterial {
  const KeyMaterial(this.privateOpenssh, this.publicOpenssh, this.fingerprint);
  final String privateOpenssh;
  final String publicOpenssh;
  final String fingerprint;
}

class KeysBridge {
  const KeysBridge();

  KeyMaterial generate(String comment) {
    final m = rs.generateEd25519Key(comment: comment);
    return KeyMaterial(m.privateOpenssh, m.publicOpenssh, m.fingerprint);
  }

  KeyMaterial import(String privateOpenssh) {
    try {
      final m = rs.importPrivateKey(privateOpenssh: privateOpenssh);
      return KeyMaterial(m.privateOpenssh, m.publicOpenssh, m.fingerprint);
    } catch (_) {
      throw const ValidationFailure('That is not an unencrypted ssh-ed25519 private key.');
    }
  }
}
