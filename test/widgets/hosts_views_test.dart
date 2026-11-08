import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/presentation/views/fingerprint_confirm_view.dart';
import 'package:openmosh/features/hosts/presentation/views/hosts_view.dart';

import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';

import '../support/fakes.dart';
import '../support/l10n_app.dart';

Widget app(Widget child, {Locale locale = const Locale('en')}) => l10nApp(
  home: Scaffold(body: child),
  locale: locale,
);

void main() {
  testWidgets('empty hosts view leads to QR pairing', (t) async {
    var paired = false;
    await t.pumpWidget(
      app(HostsView(hosts: const [], onOpen: (_) {}, onPair: () => paired = true, onAdd: () {})),
    );
    await t.tap(find.text('Scan pairing code'));
    expect(paired, isTrue);
  });

  testWidgets('hosts view lists hosts with push state', (t) async {
    await t.pumpWidget(
      app(
        HostsView(
          hosts: [testHost(deviceId: 'd', hpk: 'k')],
          onOpen: (_) {},
          onPair: () {},
          onAdd: () {},
        ),
      ),
    );
    expect(find.text('work'), findsOneWidget);
    expect(find.text('me@100.100.1.2:22'), findsNothing);
    expect(find.text('me@••••:22'), findsOneWidget);
    await t.tap(find.byTooltip('Show'));
    await t.pump();
    expect(find.text('me@100.100.1.2:22'), findsOneWidget);
    expect(find.text('push'), findsOneWidget);
  });

  testWidgets('hosts view speaks Spanish under the es locale', (t) async {
    final now = DateTime.utc(2026, 1, 1, 10);
    final e = InboxEvent.received(
      id: 'ev1',
      hostId: 'h1',
      seq: 1,
      agent: 'claude',
      kind: EventKind.approvalRequired,
      title: 'Run tests?',
      summary: '',
      pane: 'p1',
      at: now,
    );
    await t.pumpWidget(
      app(
        HostsView(
          hosts: [testHost(deviceId: 'd', hpk: 'k')],
          events: [e],
          now: now,
          onOpen: (_) {},
          onPair: () {},
          onAdd: () {},
        ),
        locale: const Locale('es'),
      ),
    );
    expect(find.text('Buenos días'), findsOneWidget);
    expect(find.text('Todo bien,\nsalvo work.', findRichText: true), findsOneWidget);
    expect(find.text('claude espera tu respuesta.'), findsOneWidget);
    expect(find.text('1 evento'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('Sesiones'), findsOneWidget);
  });

  testWidgets('fingerprint confirmation shows the fingerprint and needs an explicit tap', (
    t,
  ) async {
    var trusted = false;
    await t.pumpWidget(
      app(
        FingerprintConfirmView(
          address: 'pi',
          fingerprint: 'SHA256:abc',
          onTrust: () => trusted = true,
          onCancel: () {},
        ),
      ),
    );
    expect(find.text('SHA256:abc'), findsNothing);
    await t.tap(find.byTooltip('Show to compare'));
    await t.pump();
    expect(find.text('SHA256:abc'), findsOneWidget);
    expect(trusted, isFalse);
    await t.tap(find.textContaining('trust and save'));
    expect(trusted, isTrue);
  });
}
