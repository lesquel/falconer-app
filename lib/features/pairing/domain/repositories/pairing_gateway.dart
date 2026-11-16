import '../entities/pair_payload.dart';
import '../entities/pairing_messages.dart';

/// One-shot encrypted exchange with `falconer-hook pair` over the tailnet.
abstract interface class PairingGateway {
  Future<PairResponse> exchange(PairPayload code, PairRequestBody body);
}
