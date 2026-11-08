import '../../../../shared/crypto/openmosh_crypto.dart' as c;
import '../../../../shared/domain/b64u.dart';
import '../../../../shared/domain/failure.dart';
import '../../../hosts/domain/entities/host.dart';
import '../../../keys/domain/repositories/key_vault.dart';
import '../../domain/repositories/inbox_ports.dart';
import '../models/push_crypto.dart';

class CryptoPushOpener implements PushOpener {
  CryptoPushOpener(this._keys);
  final PushKeyStore _keys;

  @override
  Future<Map<String, Object?>> open(Host host, List<int> body) async {
    final deviceId = host.deviceId;
    final hpk = host.hostPushKey;
    if (deviceId == null || hpk == null) throw const PushFailure('Host is not paired for push.');
    final priv = await _keys.privateKey();
    try {
      return await PushCrypto.open(
        body: body,
        devicePrivate: priv,
        hostPublicKey: b64uDecode(hpk),
        deviceId: deviceId,
      );
    } finally {
      c.wipe(priv);
    }
  }
}
