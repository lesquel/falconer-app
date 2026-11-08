import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/keys/data/datasources/key_file_picker.dart';
import 'package:openmosh/features/keys/domain/entities/ssh_key_info.dart';
import 'package:openmosh/features/keys/presentation/containers/keys_container.dart';

import '../support/fakes.dart';

class ImportVault extends FakeVault {
  final imported = <String>[];
  final passphrases = <String?>[];
  @override
  Future<SshKeyInfo> import(String label, String privateOpenssh, {String? passphrase}) async {
    imported.add(privateOpenssh);
    passphrases.add(passphrase);
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

class FakeKeyFile extends KeyFilePicker {
  FakeKeyFile(this.text);
  final String? text;
  @override
  Future<String?> pickKeyText() async => text;
}

void main() {
  late List<String> clipboardCalls;
  late ImportVault vault;

  setUp(() {
    clipboardCalls = [];
    vault = ImportVault();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.openmosh/clipboard'),
      (call) async {
        clipboardCalls.add(
          call.method == 'setSensitive'
              ? 'sensitive:${(call.arguments as Map)['text']}'
              : call.method,
        );
        return null;
      },
    );
  });

  Future<void> pumpKeys(
    WidgetTester tester, {
    List<SshKeyInfo> keys = const [],
    String? file,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keysProvider.overrideWith((ref) => Stream.value(keys)),
          keyVaultProvider.overrideWithValue(vault),
          keyFilePickerProvider.overrideWithValue(FakeKeyFile(file)),
        ],
        child: const MaterialApp(home: KeysContainer()),
      ),
    );
    await tester.pump();
  }

  Future<void> openImport(WidgetTester tester, {String? file}) async {
    await pumpKeys(tester, file: file);
    await tester.tap(find.byTooltip('Import key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('private_key_field')), 'PRIVATE KEY');
  }

  testWidgets('cancelling the import dialog clears the clipboard', (tester) async {
    await openImport(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(vault.imported, isEmpty);
    expect(clipboardCalls, ['clear']);
  });

  testWidgets('importing still clears the clipboard after the import', (tester) async {
    await openImport(tester);
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(vault.imported, ['PRIVATE KEY']);
    expect(vault.passphrases, [null]);
    expect(clipboardCalls, ['clear']);
  });

  testWidgets('the pasted private key is hidden until the eye reveals it', (tester) async {
    await openImport(tester);
    final field = find.byKey(const Key('private_key_field'));
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.tap(find.descendant(of: field, matching: find.byTooltip('Show')));
    await tester.pump();
    expect(tester.widget<TextField>(field).obscureText, isFalse);
  });

  testWidgets('a passphrase-protected key is imported with its passphrase', (tester) async {
    await openImport(tester);
    final pass = find.byKey(const Key('key_passphrase'));
    expect(tester.widget<TextField>(pass).obscureText, isTrue);
    await tester.enterText(pass, 'correct horse');
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(vault.passphrases, ['correct horse']);
  });

  testWidgets('a key file chosen in the picker fills the key', (tester) async {
    await openImport(tester, file: 'FILE KEY');
    await tester.tap(find.byKey(const Key('choose_key_file')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(vault.imported, ['FILE KEY']);
  });

  testWidgets('a copied public key is marked sensitive', (tester) async {
    await pumpKeys(
      tester,
      keys: [
        SshKeyInfo(
          id: 'k',
          label: 'laptop',
          publicKey: 'ssh-ed25519 AAAAPUB',
          fingerprint: 'SHA256:x',
          imported: false,
          createdAt: DateTime.utc(2026),
        ),
      ],
    );
    await tester.tap(find.byTooltip('Copy public key'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Copy'));
    await tester.pumpAndSettle();
    expect(clipboardCalls, ['sensitive:ssh-ed25519 AAAAPUB']);
  });
}
