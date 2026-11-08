import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/keys/domain/entities/ssh_key_info.dart';
import 'package:openmosh/features/keys/presentation/containers/keys_container.dart';

import '../support/fakes.dart';

class ImportVault extends FakeVault {
  final imported = <String>[];
  @override
  Future<SshKeyInfo> import(String label, String privateOpenssh) async {
    imported.add(privateOpenssh);
    return SshKeyInfo(
      id: 'k',
      label: label,
      publicKey: 'ssh-ed25519 AAAA',
      fingerprint: 'SHA256:x',
      imported: true,
      createdAt: DateTime.utc(2026),
    );
  }
}

void main() {
  late List<String?> clipboardWrites;
  late ImportVault vault;

  setUp(() {
    clipboardWrites = [];
    vault = ImportVault();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrites.add((call.arguments as Map)['text'] as String?);
        }
        return null;
      },
    );
  });

  Future<void> openImport(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keysProvider.overrideWith((ref) => Stream.value(const <SshKeyInfo>[])),
          keyVaultProvider.overrideWithValue(vault),
        ],
        child: const MaterialApp(home: KeysContainer()),
      ),
    );
    await tester.pump();
    await tester.tap(find.byTooltip('Import key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('private_key_field')), 'PRIVATE KEY');
  }

  testWidgets('cancelling the import dialog clears the clipboard', (tester) async {
    await openImport(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vault.imported, isEmpty);
    expect(clipboardWrites, ['']);
  });

  testWidgets('importing still clears the clipboard after the import', (tester) async {
    await openImport(tester);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(vault.imported, ['PRIVATE KEY']);
    expect(clipboardWrites, ['']);
  });

  testWidgets('the pasted private key is hidden until the eye reveals it', (tester) async {
    await openImport(tester);
    final field = find.byKey(const Key('private_key_field'));
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.tap(find.descendant(of: field, matching: find.byTooltip('Show')));
    await tester.pump();
    expect(tester.widget<TextField>(field).obscureText, isFalse);
  });
}
