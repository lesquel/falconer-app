import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/entities/paired_device.dart';
import 'package:openmosh/features/hosts/presentation/views/paired_devices_view.dart';

import '../support/l10n_app.dart';

Widget app(Widget child) => l10nApp(
  home: Scaffold(body: ListView(children: [child])),
);

PairedDevice d(String id, String name, {bool me = false, bool stale = false}) => PairedDevice(
  id: id,
  name: name,
  pairedAt: DateTime.utc(2026, 11, 8, 12),
  endpointStale: stale,
  isThisPhone: me,
);

void main() {
  testWidgets('before loading it offers to show the devices', (t) async {
    var loads = 0;
    await t.pumpWidget(
      app(
        PairedDevicesView(devices: null, loading: false, onLoad: () => loads++, onRevoke: (_) {}),
      ),
    );
    expect(find.text('Paired devices'), findsOneWidget);
    await t.tap(find.text('Show paired devices'));
    expect(loads, 1);
  });

  testWidgets('lists name, paired date, stale endpoint and this phone', (t) async {
    PairedDevice? revoked;
    await t.pumpWidget(
      app(
        PairedDevicesView(
          devices: [d('a', 'Pixel', me: true), d('b', 'Tablet', stale: true)],
          loading: false,
          onLoad: () {},
          onRevoke: (x) => revoked = x,
        ),
      ),
    );
    expect(find.text('Pixel'), findsOneWidget);
    expect(find.text('this phone'), findsOneWidget);
    expect(find.textContaining('Paired 2026-11-08'), findsNWidgets(2));
    expect(find.textContaining('endpoint stale'), findsOneWidget);
    await t.tap(find.byTooltip('Revoke Tablet'));
    expect(revoked?.id, 'b');
  });
}
