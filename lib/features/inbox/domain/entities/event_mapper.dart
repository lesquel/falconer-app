/// Maps push plaintext and `inbox list` items to [InboxEvent]s.
library;

import 'inbox_event.dart';

const maxSummaryChars = 200;

/// Returns null when required fields are missing.
InboxEvent? eventFromWire(Map<String, Object?> m, {required String hostId}) {
  final id = m['id'];
  final kind = EventKind.parse(m['kind'] as String?);
  if (id is! String || id.isEmpty || id.length > 128 || kind == null) return null;
  String str(String k, int max) {
    final v = m[k];
    if (v is! String) return '';
    final clean = v.replaceAll(RegExp(r'[\x00-\x09\x0b-\x1f\x7f]'), '');
    return clean.length > max ? clean.substring(0, max) : clean;
  }

  final seq = m['seq'];
  final ts = m['ts'];
  final e = InboxEvent.received(
    id: id,
    hostId: hostId,
    seq: seq is int ? seq : 0,
    agent: str('agent', 64),
    kind: kind,
    title: str('title', 200),
    summary: str('summary', maxSummaryChars),
    pane: str('pane', 128),
    at: DateTime.fromMillisecondsSinceEpoch((ts is int ? ts : 0) * 1000, isUtc: true),
  );
  final status = m['status'] ?? m['state'];
  return status == 'resolved' || m['resolved'] == true ? e.resolvedElsewhere() : e;
}
