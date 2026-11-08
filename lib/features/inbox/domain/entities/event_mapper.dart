/// Maps push plaintext and `inbox list` items to [InboxEvent]s.
library;

import '../../../../shared/domain/display_text.dart';
import 'inbox_event.dart';

/// Longest summary kept; notifications show [notificationSummaryChars] of it
/// and the confirm screen offers the rest.
const maxSummaryChars = 2000;
const notificationSummaryChars = 200;

/// Largest accepted `ts` (9999-12-31T23:59:59Z), well inside [DateTime]'s range.
const maxEventTs = 253402300799;

/// Largest accepted `seq` (2^53 - 1, exact in every JSON implementation).
const maxEventSeq = 9007199254740991;

/// Returns null when required fields are missing or a field has the wrong type
/// or range; it never throws on hostile input.
InboxEvent? eventFromWire(Map<String, Object?> m, {required String hostId}) {
  final id = m['id'];
  final rawKind = m['kind'];
  final kind = rawKind is String ? EventKind.parse(rawKind) : null;
  if (!isWireId(id) || kind == null) return null;
  String str(String k, int max, {bool multiline = false}) {
    final v = m[k];
    return v is String ? sanitizeText(v, max: max, multiline: multiline) : '';
  }

  final seq = m['seq'] ?? 0;
  final ts = m['ts'] ?? m['created_at'] ?? 0;
  if (seq is! int || seq < 0 || seq > maxEventSeq) return null;
  if (ts is! int || ts < 0 || ts > maxEventTs) return null;
  final e = InboxEvent.received(
    id: id as String,
    hostId: hostId,
    seq: seq,
    agent: str('agent', 64),
    kind: kind,
    title: str('title', 200),
    summary: str('summary', maxSummaryChars, multiline: true),
    pane: str('pane', 128),
    at: DateTime.fromMillisecondsSinceEpoch(ts * 1000, isUtc: true),
  );
  final status = m['status'] ?? m['state'];
  return status == 'resolved' || m['resolved'] == true ? e.resolvedElsewhere() : e;
}
