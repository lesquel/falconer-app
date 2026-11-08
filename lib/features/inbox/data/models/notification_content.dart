/// What a notification may reveal (SEC-2 / T-14). Without previews the
/// notification carries only `<alias>: <agent> needs you` — never the
/// title or summary — and is safe to show on the lock screen.
library;

import '../../domain/entities/inbox_event.dart';

final class NotificationContent {
  const NotificationContent({
    required this.title,
    required this.body,
    required this.lockScreenSafe,
  });
  final String title;
  final String? body;

  /// When false the notification is VISIBILITY_PRIVATE, so a secure lock
  /// screen shows only that a notification exists.
  final bool lockScreenSafe;
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
  if (!preview) return NotificationContent(title: generic, body: null, lockScreenSafe: true);
  return NotificationContent(
    title: e.title.isEmpty ? generic : '$hostAlias · ${e.title}',
    body: e.summary.isEmpty ? null : e.summary,
    lockScreenSafe: false,
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

/// Payload routed back to the app; contains ids only.
String notificationPayload(String hostId, String eventId, [String? action]) => Uri(
  path: '/inbox/$hostId/$eventId',
  queryParameters: action == null ? null : {'action': action},
).toString();
