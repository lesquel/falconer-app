import '../entities/herdr_action.dart';
import '../entities/herdr_snapshot.dart';

/// Herdr navigator port: structured state and allowlisted actions of a
/// host's Herdr session, through `openmosh-hook herdr …`.
abstract interface class HerdrRepository {
  /// Whether the host's hook speaks the Herdr navigator protocol (`herdr` ≥ 1).
  Future<bool> supportsHerdr(String hostId);

  Future<Polled<HerdrSnapshot>> snapshot(
    String hostId, {
    String? session,
    String? since,
    int waitMs = 0,
  });

  Future<Polled<PaneScreen>> read(
    String hostId,
    String paneId, {
    String? session,
    String? since,
    int waitMs = 0,
  });

  /// Runs [action]; returns the new id for create/start actions.
  Future<String?> act(String hostId, HerdrAction action, {String? session});
}
