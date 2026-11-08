import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../domain/entities/ssh_key_info.dart';
import '../views/keys_view.dart';

class KeysContainer extends ConsumerWidget {
  const KeysContainer({super.key});

  Future<void> _guard(BuildContext context, Future<void> Function() f) async {
    final m = ScaffoldMessenger.of(context);
    final l = context.l10n;
    try {
      await f();
    } on AppFailure catch (e) {
      m.showSnackBar(SnackBar(content: Text(l.failureMessage(e.message))));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<({String label, String pem})>(
      context: context,
      builder: (_) => const _ImportKeyDialog(),
    );
    // The private key may have been pasted from the clipboard: clear it
    // whether the dialog was confirmed or cancelled.
    await Clipboard.setData(const ClipboardData(text: ''));
    if (result == null || !context.mounted) return;
    final fallback = context.l10n.importedKeyLabel;
    await _guard(
      context,
      () => ref
          .read(keyVaultProvider)
          .import(result.label.isEmpty ? fallback : result.label, result.pem),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, SshKeyInfo k) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteKeyTitle(k.label)),
        content: Text(l.deleteKeyBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok == true) await ref.read(keyVaultProvider).delete(k.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(keysProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.keysTitle),
        actions: [
          IconButton(
            tooltip: l.generateKey,
            icon: const Icon(Icons.add),
            onPressed: () => _guard(
              context,
              () => ref
                  .read(keyVaultProvider)
                  .generate(l.generatedKeyLabel(DateTime.now().toIso8601String().substring(0, 10))),
            ),
          ),
          IconButton(
            tooltip: l.importKey,
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () => _import(context, ref),
          ),
        ],
      ),
      body: keys.when(
        data: (list) => KeysView(
          keys: list,
          onCopyPublic: (k) async {
            final m = ScaffoldMessenger.of(context);
            await Clipboard.setData(ClipboardData(text: k.publicKey));
            m.showSnackBar(SnackBar(content: Text(l.publicKeyCopied)));
          },
          onDelete: (k) => _delete(context, ref, k),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FailurePanel(failure: e),
      ),
    );
  }
}

/// Owns its controllers so they are disposed only after the dialog route is
/// gone; the pasted key is cleared from the field on dispose.
class _ImportKeyDialog extends StatefulWidget {
  const _ImportKeyDialog();

  @override
  State<_ImportKeyDialog> createState() => _ImportKeyDialogState();
}

class _ImportKeyDialogState extends State<_ImportKeyDialog> {
  late final _label = TextEditingController(text: context.l10n.importedKeyLabel);
  final _pem = TextEditingController();

  @override
  void dispose() {
    _pem.clear();
    _pem.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.importKeyTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: l.keyLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pem,
            minLines: 4,
            maxLines: 8,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: InputDecoration(labelText: l.pastePrivateKey),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (label: _label.text.trim(), pem: _pem.text)),
          child: Text(l.importAction),
        ),
      ],
    );
  }
}
