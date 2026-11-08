import 'package:flutter/material.dart';
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
    final result = await showDialog<({String label, String pem, String passphrase})>(
      context: context,
      builder: (_) => _ImportKeyDialog(pickFile: ref.read(keyFilePickerProvider).pickKeyText),
    );
    // The private key may have been pasted from the clipboard: clear it
    // whether the dialog was confirmed or cancelled.
    await ref.read(secureClipboardProvider).clear();
    if (result == null || !context.mounted) return;
    final fallback = context.l10n.importedKeyLabel;
    await _guard(
      context,
      () => ref
          .read(keyVaultProvider)
          .import(
            result.label.isEmpty ? fallback : result.label,
            result.pem,
            passphrase: result.passphrase.isEmpty ? null : result.passphrase,
          ),
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
            await ref.read(secureClipboardProvider).copySensitive(k.publicKey);
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
  const _ImportKeyDialog({required this.pickFile});

  /// Reads a key file from the system picker; null when nothing was chosen.
  final Future<String?> Function() pickFile;

  @override
  State<_ImportKeyDialog> createState() => _ImportKeyDialogState();
}

class _ImportKeyDialogState extends State<_ImportKeyDialog> {
  late final _label = TextEditingController(text: context.l10n.importedKeyLabel);
  final _pem = TextEditingController();
  final _passphrase = TextEditingController();
  bool _showPem = false;
  String? _error;

  @override
  void dispose() {
    _pem.clear();
    _pem.dispose();
    _passphrase.clear();
    _passphrase.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    try {
      final text = await widget.pickFile();
      if (text != null && mounted) setState(() => (_pem.text = text, _error = null));
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.importKeyTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            decoration: InputDecoration(labelText: l.keyLabel),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('private_key_field'),
            controller: _pem,
            obscureText: !_showPem,
            // An obscured field is one line; revealed, the key wraps.
            minLines: _showPem ? 4 : 1,
            maxLines: _showPem ? 8 : 1,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            decoration: InputDecoration(
              labelText: l.pastePrivateKey,
              suffixIcon: IconButton(
                tooltip: _showPem ? l.hideSensitive : l.showSensitive,
                icon: Icon(_showPem ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                onPressed: () => setState(() => _showPem = !_showPem),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('choose_key_file'),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(l.chooseKeyFile),
              onPressed: _chooseFile,
            ),
          ),
          TextField(
            key: const Key('key_passphrase'),
            controller: _passphrase,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            decoration: InputDecoration(labelText: l.keyPassphrase),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l.failureMessage(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            label: _label.text.trim(),
            pem: _pem.text,
            passphrase: _passphrase.text,
          )),
          child: Text(l.importAction),
        ),
      ],
    );
  }
}
