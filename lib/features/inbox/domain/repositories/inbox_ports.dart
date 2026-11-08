import '../../../hosts/domain/entities/host.dart';
import '../entities/inbox_event.dart';

abstract interface class InboxRepository {
  Stream<List<InboxEvent>> watchAll();
  Future<InboxEvent?> byId(String hostId, String id);
  Future<void> upsert(InboxEvent event);
  Future<int> maxSeq(String hostId);
  Future<int> pendingCount();
}

/// UnifiedPush registration. Pairing reads the endpoint through this port.
abstract interface class PushEndpointSource {
  /// Registers with the distributor if needed. Throws `PushFailure` when no
  /// UnifiedPush distributor (e.g. ntfy) is installed.
  Future<String> currentEndpoint();

  /// Last known endpoint without registering, if any.
  Future<String?> knownEndpoint();
}

/// Decrypts a push body for [host]; throws `PushFailure` when invalid.
abstract interface class PushOpener {
  Future<Map<String, Object?>> open(Host host, List<int> body);
}

abstract interface class EventNotifier {
  Future<void> show(InboxEvent event, {required String hostAlias, required bool preview});
  Future<void> cancel(String hostId, String eventId);
}

/// Per host, the `seq` up to which `inbox list` was read (the hook's
/// `last_seq`). Only sync moves it: pushes can arrive out of order, so the
/// highest pushed seq says nothing about gaps. `0` before the first sync.
abstract interface class SyncCursorStore {
  Future<int> read(String hostId);
  Future<void> write(String hostId, int seq);
}
