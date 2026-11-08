import '../../domain/entities/pair_payload.dart';
import '../../domain/repositories/pairing_gateway.dart';
import '../datasources/pair_socket.dart';
import '../models/pair_crypto.dart';

class TcpPairingGateway implements PairingGateway {
  const TcpPairingGateway([this._socket = const PairSocket()]);
  final PairSocket _socket;

  @override
  Future<PairResponse> exchange(PairPayload code, PairRequestBody body) async {
    final sealed = await PairCrypto.sealRequest(
      hostPublicKey: code.hostPublicKey,
      token: code.token,
      plaintext: body.toJsonBytes(),
    );
    final reply = await _socket.roundTrip(code.ip, code.pairPort, sealed.line);
    return PairCrypto.openResponse(reply, sealed.responseKey);
  }
}
