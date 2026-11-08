import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/domain/entities/notification_hours.dart';
import 'package:openmosh/features/settings/presentation/views/notification_hours_tile.dart';

import '../support/l10n_app.dart';

void main() {
  testWidgets('the app row sets a window between two hours', (t) async {
    HoursChoice? got;
    await t.pumpWidget(
      l10nApp(
        home: Scaffold(body: NotificationHoursTile(hours: null, onChanged: (c) => got = c)),
      ),
    );
    expect(find.text('Always'), findsOneWidget);
    await t.tap(find.byKey(const Key('notification_hours')));
    await t.pumpAndSettle();
    expect(find.text('Use the app setting'), findsNothing);
    await t.tap(find.text('Only between'));
    await t.pumpAndSettle();
    expect(find.text('From 08:00'), findsOneWidget);
    await t.tap(find.byKey(const Key('notify_save')));
    await t.pumpAndSettle();
    expect((got! as SetHours).hours, const NotificationHours(480, 1260));
  });

  testWidgets('a host row shows the app setting and can go back to it', (t) async {
    HoursChoice? got;
    await t.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: NotificationHoursTile(
            hours: const NotificationHours(540, 1080),
            inherited: () => const NotificationHours(480, 1260),
            onChanged: (c) => got = c,
          ),
        ),
      ),
    );
    expect(find.text('09:00 – 18:00'), findsOneWidget);
    await t.tap(find.byKey(const Key('notification_hours')));
    await t.pumpAndSettle();
    await t.tap(find.text('Use the app setting'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('notify_save')));
    await t.pumpAndSettle();
    expect(got, isA<InheritHours>());
  });

  testWidgets('Spanish labels', (t) async {
    await t.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: NotificationHoursTile(hours: null, inherited: () => null, onChanged: (_) {}),
        ),
        locale: const Locale('es'),
      ),
    );
    expect(find.text('Horario de notificaciones'), findsOneWidget);
    expect(find.text('Ajuste de la app: Siempre'), findsOneWidget);
  });
}
