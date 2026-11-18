/// flutter_local_notifications adapter. No content leaves the device: this
/// only renders what [notificationContent] allows.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/inbox_event.dart';
import '../../domain/entities/suggested_answer.dart';
import '../../domain/repositories/inbox_ports.dart';
import '../models/notification_content.dart';

typedef NotificationTap = void Function(String path, SuggestedAnswer? answer);

/// Where a notification response leads: the event's path, plus the answer of
/// the Approve or Deny button that was tapped. The answer stays out of the
/// path, so the router never reads it from a URL.
typedef NotificationRoute = ({String path, SuggestedAnswer? answer});

NotificationRoute notificationRoute(String payload, String? actionId) => (
  path: Uri.parse(payload).path,
  answer: actionId == null || actionId == 'open' ? null : SuggestedAnswer(actionId),
);

class LocalEventNotifier implements EventNotifier {
  LocalEventNotifier(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Route for the notification that launched the app, if any.
  Future<NotificationRoute?> launchRoute() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    final r = d?.notificationResponse;
    if (d?.didNotificationLaunchApp != true || r?.payload == null) return null;
    return notificationRoute(r!.payload!, r.actionId);
  }

  static const channelId = 'agent_events';

  static const _darwinSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );

  static Future<FlutterLocalNotificationsPlugin> init({NotificationTap? onTap}) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Permission is requested later by [requestPermission], not at init.
        iOS: _darwinSettings,
        macOS: _darwinSettings,
      ),
      onDidReceiveNotificationResponse: (r) => _route(r, onTap),
    );
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            channelId,
            'Agent events',
            description: 'An agent needs approval, has a question or finished',
            importance: Importance.high,
          ),
        );
    return plugin;
  }

  static void _route(NotificationResponse r, NotificationTap? onTap) {
    final p = r.payload;
    if (p == null || onTap == null) return;
    final route = notificationRoute(p, r.actionId);
    onTap(route.path, route.answer);
  }

  @override
  Future<void> show(InboxEvent e, {required String hostAlias, required bool preview}) async {
    final content = notificationContent(e, hostAlias: hostAlias, preview: preview);
    // Actions only open the app; the confirm screen asks for biometrics.
    final actions = e.kind.actionable
        ? const [
            AndroidNotificationAction('allow', 'Approve', showsUserInterface: true),
            AndroidNotificationAction('deny', 'Deny', showsUserInterface: true),
            AndroidNotificationAction('open', 'Open', showsUserInterface: true),
          ]
        : const <AndroidNotificationAction>[];
    await _plugin.show(
      id: notificationId(e.hostId, e.id),
      title: content.title,
      body: content.body,
      payload: notificationPayload(e.hostId, e.id),
      notificationDetails: NotificationDetails(android: androidDetails(actions)),
    );
  }

  /// Always VISIBILITY_PRIVATE: a secure lock screen shows only that
  /// Falconer has a notification, never the host alias or agent. The plugin
  /// cannot attach a custom public version, so Android shows its own
  /// redacted one ("Contents hidden").
  static AndroidNotificationDetails androidDetails(List<AndroidNotificationAction> actions) =>
      AndroidNotificationDetails(
        channelId,
        'Agent events',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.message,
        visibility: NotificationVisibility.private,
        actions: actions,
      );

  @override
  Future<void> cancel(String hostId, String eventId) =>
      _plugin.cancel(id: notificationId(hostId, eventId));
}
