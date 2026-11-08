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

const keyImportFailed = 'That is not an ssh-ed25519 private key, or the passphrase is wrong.';

class KeysBridge {
  const KeysBridge();

  KeyMaterial generate(String comment) {
    final m = rs.generateEd25519Key(comment: comment);
    return KeyMaterial(m.privateOpenssh, m.publicOpenssh, m.fingerprint);
  }

  KeyMaterial import(String privateOpenssh, {String? passphrase}) {
    try {
      final m = rs.importPrivateKey(privateOpenssh: privateOpenssh, passphrase: passphrase);
      return KeyMaterial(m.privateOpenssh, m.publicOpenssh, m.fingerprint);
    } catch (_) {
      throw const ValidationFailure(keyImportFailed);
    }
  }
}
