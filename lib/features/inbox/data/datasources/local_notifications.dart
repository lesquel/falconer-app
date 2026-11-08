/// flutter_local_notifications adapter. No content leaves the device: this
/// only renders what [notificationContent] allows.
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/inbox_event.dart';
import '../../domain/repositories/inbox_ports.dart';
import '../models/notification_content.dart';

typedef NotificationTap = void Function(String payload);

class LocalEventNotifier implements EventNotifier {
  LocalEventNotifier(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Route for the notification that launched the app, if any.
  Future<String?> launchPayload() async {
    final d = await _plugin.getNotificationAppLaunchDetails();
    final r = d?.notificationResponse;
    if (d?.didNotificationLaunchApp != true || r?.payload == null) return null;
    final uri = Uri.parse(r!.payload!);
    final a = r.actionId;
    return a == null || a == 'open'
        ? uri.path
        : Uri(path: uri.path, queryParameters: {'action': a}).toString();
  }

  static const channelId = 'agent_events';

  static Future<FlutterLocalNotificationsPlugin> init({NotificationTap? onTap}) async {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
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
    final action = r.actionId;
    if (action == null || action == 'open') return onTap(p);
    final uri = Uri.parse(p);
    onTap(Uri(path: uri.path, queryParameters: {'action': action}).toString());
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
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Agent events',
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          visibility: content.lockScreenSafe
              ? NotificationVisibility.public
              : NotificationVisibility.private,
          actions: actions,
        ),
      ),
    );
  }

  @override
  Future<void> cancel(String hostId, String eventId) =>
      _plugin.cancel(id: notificationId(hostId, eventId));
}
