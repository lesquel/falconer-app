/// What a notification may reveal (SEC-2 / T-14). Without previews the
/// notification carries only `<alias>: <agent> needs you` — never the
/// title or summary. Every notification is VISIBILITY_PRIVATE, so a secure
/// lock screen never shows the host alias either.
library;

import '../../../../shared/domain/display_text.dart';
import '../../domain/entities/event_mapper.dart';
import '../../domain/entities/inbox_event.dart';

final class NotificationContent {
  const NotificationContent({required this.title, required this.body});
  final String title;
  final String? body;
}

String genericLine(String alias, String agent) =>
    '$alias: ${agent.isEmpty ? 'an agent' : agent} needs you';

NotificationContent notificationContent(
  InboxEvent e, {
  required String hostAlias,
  required bool preview,
}) {
  final generic = e.kind == EventKind.done
      ? '$hostAlias: ${e.agent.isEmpty ? 'an agent' : e.agent} finished'
      : genericLine(hostAlias, e.agent);
  if (!preview) return NotificationContent(title: generic, body: null);
  return NotificationContent(
    title: e.title.isEmpty ? generic : '$hostAlias · ${e.title}',
    body: e.summary.isEmpty ? null : truncateText(e.summary, notificationSummaryChars),
  );
}

/// Stable 31-bit id per (host, event) so a later push can cancel it.
int notificationId(String hostId, String eventId) {
  var h = 0x811c9dc5;
  for (final c in '$hostId/$eventId'.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0x7fffffff;
  }
  return h;
}

/// Payload routed back to the app; contains ids only, each as one encoded
/// path segment so an id can never add or remove segments.
String notificationPayload(String hostId, String eventId) =>
    Uri(pathSegments: ['', 'inbox', hostId, eventId]).toString();
