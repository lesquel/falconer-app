import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/mask.dart';
import '../../../../shared/ui/atoms/sensitive_text.dart';
import '../../domain/entities/ssh_key_info.dart';

class KeysView extends StatelessWidget {
  const KeysView({
    super.key,
    required this.keys,
    required this.onCopyPublic,
    required this.onDelete,
  });

  final List<SshKeyInfo> keys;

  /// Called after the user confirms the copy.
  final ValueChanged<SshKeyInfo> onCopyPublic;
  final ValueChanged<SshKeyInfo> onDelete;

  Future<void> _confirmCopy(BuildContext context, SshKeyInfo k) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.copyPublicKeyTitle),
        content: Text(l.copyPublicKeyBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.copy)),
        ],
      ),
    );
    if (ok == true) onCopyPublic(k);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (keys.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.keysEmpty, textAlign: TextAlign.center),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final k in keys)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(k.imported ? Icons.file_download_outlined : Icons.key),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(k.label, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      IconButton(
                        tooltip: l.copyPublicKey,
                        icon: const Icon(Icons.copy),
                        onPressed: () => _confirmCopy(context, k),
                      ),
                      IconButton(
                        tooltip: l.delete,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(k),
                      ),
                    ],
                  ),
                  SensitiveText(
                    k.fingerprint,
                    masked: maskFingerprint(k.fingerprint),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                  SensitiveText(
                    k.publicKey,
                    masked: maskPublicKey(k.publicKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
