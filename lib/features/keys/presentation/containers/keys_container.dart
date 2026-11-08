import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../domain/entities/ssh_key_info.dart';
import '../views/keys_view.dart';

class KeysContainer extends ConsumerWidget {
  const KeysContainer({super.key});

  Future<void> _guard(BuildContext context, Future<void> Function() f) async {
    final m = ScaffoldMessenger.of(context);
    try {
      await f();
    } on AppFailure catch (e) {
      m.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final label = TextEditingController(text: 'Imported key');
    final pem = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Import ssh-ed25519 key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(labelText: 'Label'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: pem,
              minLines: 4,
              maxLines: 8,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.visiblePassword,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              decoration: const InputDecoration(labelText: 'Paste the OpenSSH private key'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Import')),
        ],
      ),
    );
    final text = pem.text;
    pem.clear();
    pem.dispose();
    if (ok == true && context.mounted) {
      await _guard(
        context,
        () => ref
            .read(keyVaultProvider)
            .import(label.text.trim().isEmpty ? 'Imported key' : label.text.trim(), text),
      );
      // The private key may have been pasted from the clipboard: clear it.
      await Clipboard.setData(const ClipboardData(text: ''));
    }
    label.dispose();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, SshKeyInfo k) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete ${k.label}?'),
        content: const Text(
          'Hosts that use this key will stop connecting until you pair them again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) await ref.read(keyVaultProvider).delete(k.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keys = ref.watch(keysProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keys'),
        actions: [
          IconButton(
            tooltip: 'Generate key',
            icon: const Icon(Icons.add),
            onPressed: () => _guard(
              context,
              () => ref
                  .read(keyVaultProvider)
                  .generate('Key ${DateTime.now().toIso8601String().substring(0, 10)}'),
            ),
          ),
          IconButton(
            tooltip: 'Import key',
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
            m.showSnackBar(const SnackBar(content: Text('Public key copied')));
          },
          onDelete: (k) => _delete(context, ref, k),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => FailurePanel(failure: e),
      ),
    );
  }
}
