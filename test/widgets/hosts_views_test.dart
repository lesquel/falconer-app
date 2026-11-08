import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/presentation/views/fingerprint_confirm_view.dart';
import 'package:openmosh/features/hosts/presentation/views/hosts_view.dart';
import '../support/fakes.dart';

Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('empty hosts view leads to QR pairing', (t) async {
    var paired = false;
    await t.pumpWidget(app(HostsView(hosts: const [], onOpen: (_) {}, onPair: () => paired = true, onAdd: () {})));
    await t.tap(find.text('Scan pairing code'));
    expect(paired, isTrue);
  });

  testWidgets('hosts view lists hosts with push state', (t) async {
    await t.pumpWidget(app(HostsView(hosts: [testHost(deviceId: 'd', hpk: 'k')], onOpen: (_) {}, onPair: () {}, onAdd: () {})));
    expect(find.text('work'), findsOneWidget);
    expect(find.text('me@100.100.1.2:22'), findsOneWidget);
    expect(find.text('push'), findsOneWidget);
  });

  testWidgets('fingerprint confirmation shows the fingerprint and needs an explicit tap', (t) async {
    var trusted = false;
    await t.pumpWidget(app(FingerprintConfirmView(
        address: 'pi', fingerprint: 'SHA256:abc', onTrust: () => trusted = true, onCancel: () {})));
    expect(find.text('SHA256:abc'), findsOneWidget);
    expect(trusted, isFalse);
    await t.tap(find.textContaining('trust and save'));
    expect(trusted, isTrue);
  });
}
