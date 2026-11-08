import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/mono_text.dart';
import '../../domain/entities/ssh_key_info.dart';

class KeysView extends StatelessWidget {
  const KeysView({
    super.key,
    required this.keys,
    required this.onCopyPublic,
    required this.onDelete,
  });

  final List<SshKeyInfo> keys;
  final ValueChanged<SshKeyInfo> onCopyPublic;
  final ValueChanged<SshKeyInfo> onDelete;

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No keys yet. Pairing creates this device\'s key, or generate/import one.',
            textAlign: TextAlign.center,
          ),
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
                        tooltip: 'Copy public key',
                        icon: const Icon(Icons.copy),
                        onPressed: () => onCopyPublic(k),
                      ),
                      IconButton(
                        tooltip: 'Delete',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => onDelete(k),
                      ),
                    ],
                  ),
                  MonoText(k.fingerprint),
                  const SizedBox(height: 4),
                  Text(
                    k.publicKey,
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
