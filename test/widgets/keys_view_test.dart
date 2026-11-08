import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keys/domain/entities/ssh_key_info.dart';
import 'package:openmosh/features/keys/presentation/views/keys_view.dart';

import '../support/l10n_app.dart';

void main() {
  final key = SshKeyInfo(
    id: 'k',
    label: 'laptop',
    publicKey: 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA me@phone',
    fingerprint: 'SHA256:abcdefghijklmnopqrstuvwxyz',
    imported: false,
    createdAt: DateTime.utc(2026),
  );

  Future<List<SshKeyInfo>> pump(WidgetTester t) async {
    final copied = <SshKeyInfo>[];
    await t.pumpWidget(
      l10nApp(
        home: Scaffold(
          body: KeysView(keys: [key], onCopyPublic: copied.add, onDelete: (_) {}),
        ),
      ),
    );
    return copied;
  }

  testWidgets('the fingerprint and public key are masked until revealed', (t) async {
    await pump(t);
    expect(find.text('laptop'), findsOneWidget);
    expect(find.text(key.fingerprint), findsNothing);
    expect(find.text(key.publicKey), findsNothing);
    expect(find.text('SHA256:ab••••••yz'), findsOneWidget);
    expect(find.text('ssh-ed25519 AAAA••••…'), findsOneWidget);
    await t.tap(find.byTooltip('Show').last);
    await t.pump();
    expect(find.text(key.publicKey), findsOneWidget);
    expect(find.text(key.fingerprint), findsNothing, reason: 'each value has its own eye');
  });

  testWidgets('copying the public key asks first', (t) async {
    final copied = await pump(t);
    await t.tap(find.byTooltip('Copy public key'));
    await t.pumpAndSettle();
    expect(find.text('Copy the public key?'), findsOneWidget);
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(copied, isEmpty);
    await t.tap(find.byTooltip('Copy public key'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(FilledButton, 'Copy'));
    await t.pumpAndSettle();
    expect(copied, [key]);
  });
}
