/// Inbox flows: incoming pushes, responses over SSH, and sync on connect.
library;

import '../../../../shared/domain/clock.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../hosts/domain/repositories/host_repository.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../entities/event_mapper.dart';
import '../entities/inbox_event.dart';
import '../entities/push_freshness.dart';
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
    required this.now,
  });

  final HostRepository hosts;
  final InboxRepository inbox;
  final PushOpener opener;
  final EventNotifier notifier;
  final PreviewsEnabled previews;
  final KidOf kidOf;
  final Clock now;

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
    // Hook seqs start at 1; a push without one cannot be told from a replay.
    if (incoming == null || incoming.seq < 1) return null;
    // Replay guard: the ciphertext is authentic but may be old. Pushes are
    // sent by separate processes and can arrive out of order, so there is no
    // per-device high-water mark: a push is a replay when this event already
    // holds its seq or a later one (resolved pushes reuse the id with a new
    // seq). The ts window bounds replays of events no longer stored.
    if (!isFreshPush(incoming.at, now())) {
      Log.warning('push', 'discarded stale message');
      return null;
    }
    final existing = await inbox.byId(host.id, incoming.id);
    if (existing != null && existing.seq >= incoming.seq) {
      Log.warning('push', 'discarded replayed message');
      return null;
    }

    if (incoming.kind == EventKind.resolved) {
      if (existing == null) return null;
      final r = existing.resolvedElsewhere(atSeq: incoming.seq);
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
  const SyncInbox({required this.inbox, required this.cursors, required this.connections});

  final InboxRepository inbox;
  final SyncCursorStore cursors;
  final HostConnections connections;

  static const pageSize = 200;
  static const maxPages = 10;

  /// Reads `inbox list` pages after the stored cursor (not after the highest
  /// stored seq: an event pushed late or lost would be skipped forever).
  Future<int> call(String hostId) async {
    var since = await cursors.read(hostId);
    var n = 0;
    for (var page = 0; page < maxPages; page++) {
      final data = await connections.runHook(
        hostId,
        HookCommand.inboxList(since: since, limit: pageSize),
      );
      final items = data is List ? data : (data is Map ? data['events'] : null);
      if (items is! List || items.isEmpty) break;
      var last = since;
      for (final raw in items) {
        if (raw is! Map<String, Object?>) continue;
        final incoming = eventFromWire(raw, hostId: hostId);
        if (incoming == null) continue;
        if (incoming.seq > last) last = incoming.seq;
        if (incoming.kind == EventKind.resolved) continue;
        final existing = await inbox.byId(hostId, incoming.id);
        await inbox.upsert(existing?.mergeIncoming(incoming) ?? incoming);
        n++;
      }
      final reported = data is Map ? data['last_seq'] : null;
      if (reported is int && reported > last) last = reported;
      if (last <= since) break;
      since = last;
      await cursors.write(hostId, since);
      if (items.length < pageSize) break;
    }
    return n;
  }
}
