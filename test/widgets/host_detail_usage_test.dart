import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/presentation/views/host_detail_view.dart';

import '../support/fakes.dart';
import '../support/l10n_app.dart';

void main() {
  testWidgets('the host screen opens "Agent usage"', (t) async {
    var opened = 0;
    await t.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: HostDetailView(
            host: testHost(),
            sessions: null,
            agents: null,
            loading: false,
            onLoad: () {},
            onShell: () {},
            onAttach: (_) {},
            onEnablePush: () {},
            onUsage: () => opened++,
          ),
        ),
      ),
    );
    await t.tap(find.text('Agent usage'));
    expect(opened, 1);
    expect(
      t.getSize(find.widgetWithText(OutlinedButton, 'Agent usage')).height,
      greaterThanOrEqualTo(44),
    );
  });

  testWidgets('the host screen opens Herdr with one tap; no button without Herdr', (t) async {
    var opened = 0;
    Widget view(VoidCallback? onHerdr) => l10nApp(
      home: Scaffold(
        body: HostDetailView(
          host: testHost(),
          sessions: null,
          agents: null,
          loading: false,
          onLoad: () {},
          onShell: () {},
          onAttach: (_) {},
          onEnablePush: () {},
          onHerdr: onHerdr,
        ),
      ),
    );
    await t.pumpWidget(view(() => opened++));
    await t.tap(find.byKey(const Key('open_herdr')));
    expect(opened, 1);
    await t.pumpWidget(view(null));
    expect(find.byKey(const Key('open_herdr')), findsNothing);
  });

  testWidgets('the host screen masks the address and the pinned host key', (t) async {
    final host = testHost();
    await t.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: HostDetailView(
            host: host,
            sessions: null,
            agents: null,
            loading: false,
            onLoad: () {},
            onShell: () {},
            onAttach: (_) {},
            onEnablePush: () {},
          ),
        ),
      ),
    );
    expect(find.text('${host.user}@${host.address}:${host.port}'), findsNothing);
    expect(find.text('${host.user}@••••:${host.port}'), findsOneWidget);
    expect(find.text(host.fingerprint), findsNothing);
  });
}
