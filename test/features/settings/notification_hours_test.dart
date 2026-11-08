import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/domain/entities/notification_hours.dart';

DateTime at(int h, int m) => DateTime(2026, 11, 8, h, m);

void main() {
  test('a daytime window allows its hours only', () {
    const w = NotificationHours(8 * 60, 21 * 60);
    expect(w.allows(at(7, 59)), isFalse);
    expect(w.allows(at(8, 0)), isTrue);
    expect(w.allows(at(20, 59)), isTrue);
    expect(w.allows(at(21, 0)), isFalse);
  });

  test('a window may cross midnight; equal ends mean all day', () {
    const night = NotificationHours(22 * 60, 2 * 60);
    expect(night.allows(at(23, 30)), isTrue);
    expect(night.allows(at(1, 0)), isTrue);
    expect(night.allows(at(12, 0)), isFalse);
    expect(const NotificationHours(0, 0).allows(at(3, 0)), isTrue);
  });

  test('windows encode and parse; bad text is ignored', () {
    expect(NotificationHours.parse('480-1260'), const NotificationHours(480, 1260));
    expect(const NotificationHours(480, 1260).encode(), '480-1260');
    for (final bad in [null, '', '480', 'a-b', '-1-30', '480-1440']) {
      expect(NotificationHours.parse(bad), isNull, reason: '$bad');
    }
  });

  test('a host window replaces the app window; no window means always', () {
    var s = const AppSettings();
    expect(s.notificationsAllowed('h1', at(3, 0)), isTrue);
    s = s.withNotificationHours(const NotificationHours(8 * 60, 21 * 60));
    expect(s.notificationsAllowed('h1', at(3, 0)), isFalse);
    s = s.withHostNotificationHours('h1', const NotificationHours(0, 0));
    expect(s.notificationsAllowed('h1', at(3, 0)), isTrue);
    expect(s.notificationsAllowed('h2', at(3, 0)), isFalse);
    s = s.withHostNotificationHours('h1', null).withNotificationHours(null);
    expect(s.notificationsAllowed('h1', at(3, 0)), isTrue);
  });
}
