/// Inbox flows: incoming pushes, responses over SSH, and sync on connect.
library;

import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../hosts/domain/repositories/host_repository.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../entities/event_mapper.dart';
import '../entities/inbox_event.dart';
import '../repositories/inbox_ports.dart';

typedef PreviewsEnabled = Future<bool> Function();
typedef KidOf = String? Function(List<int> body);

final class HandlePushMessage {
  const HandlePushMessage({
    required this.hosts,
    required this.inbox,
    required this.opener,
    required this.notifier,
    required this.previews,
    required this.kidOf,
  });

  final HostRepository hosts;
  final InboxRepository inbox;
  final PushOpener opener;
  final EventNotifier notifier;
  final PreviewsEnabled previews;
  final KidOf kidOf;

  /// Returns the stored event, or null when the message was discarded.
  Future<InboxEvent?> call(List<int> body) async {
    final kid = kidOf(body);
    if (kid == null) return null;
    final host = await hosts.byDeviceId(kid);
    if (host == null || !host.pushEnabled) return null;
    final Map<String, Object?> plain;
    try {
      plain = await opener.open(host, body);
    } on PushFailure {
      Log.warning('push', 'discarded undecryptable message');
      return null;
    }
    final incoming = eventFromWire(plain, hostId: host.id);
    if (incoming == null) return null;
    final existing = await inbox.byId(host.id, incoming.id);

    if (incoming.kind == EventKind.resolved) {
      if (existing == null) return null;
      final r = existing.resolvedElsewhere();
      await inbox.upsert(r);
      await notifier.cancel(host.id, r.id);
      return r;
    }
    final merged = existing?.mergeIncoming(incoming) ?? incoming;
    await inbox.upsert(merged);
    if (existing == null && merged.status != InboxStatus.resolved) {
      await notifier.show(merged, hostAlias: host.alias, preview: await previews());
    }
    return merged;
  }
}

final class RespondToEvent {
  const RespondToEvent({required this.inbox, required this.connections, required this.notifier});

  final InboxRepository inbox;
  final HostConnections connections;
  final EventNotifier notifier;

  Future<InboxEvent> call(String hostId, String eventId, ResponseKind kind, {String? text}) async {
    final event = await inbox.byId(hostId, eventId);
    if (event == null) throw const ValidationFailure('Event not found.');
    final cmd = HookCommand.respond(eventId, RespondAction.values.byName(kind.name), text: text);
    final responding = event.startResponding(kind);
    await inbox.upsert(responding);
    try {
      await connections.runHook(hostId, cmd);
    } catch (_) {
      await inbox.upsert(responding.responseFailed());
      rethrow;
    }
    final done = responding.responseSucceeded();
    await inbox.upsert(done);
    await notifier.cancel(hostId, eventId);
    return done;
  }
}

final class SyncInbox {
  const SyncInbox({required this.inbox, required this.connections});

  final InboxRepository inbox;
  final HostConnections connections;

  Future<int> call(String hostId) async {
    final since = await inbox.maxSeq(hostId);
    final data = await connections.runHook(hostId, HookCommand.inboxList(since: since, limit: 200));
    final items = data is List ? data : (data is Map ? data['events'] : null);
    if (items is! List) return 0;
    var n = 0;
    for (final raw in items) {
      if (raw is! Map<String, Object?>) continue;
      final incoming = eventFromWire(raw, hostId: hostId);
      if (incoming == null || incoming.kind == EventKind.resolved) continue;
      final existing = await inbox.byId(hostId, incoming.id);
      await inbox.upsert(existing?.mergeIncoming(incoming) ?? incoming);
      n++;
    }
    return n;
  }
}
