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
}
