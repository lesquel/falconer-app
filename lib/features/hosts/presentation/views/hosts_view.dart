import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/status_badge.dart';
import '../../domain/entities/host.dart';

class HostsView extends StatelessWidget {
  const HostsView({
    super.key,
    required this.hosts,
    required this.onOpen,
    required this.onPair,
    required this.onAdd,
  });

  final List<Host> hosts;
  final ValueChanged<Host> onOpen;
  final VoidCallback onPair;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Run `openmosh-hook pair` on your computer, then scan the code.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onPair,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan pairing code'),
              ),
              TextButton(onPressed: onAdd, child: const Text('Add host manually')),
            ],
          ),
        ),
      );
    }
    return ListView(
      children: [
        for (final h in hosts)
          ListTile(
            leading: const Icon(Icons.computer),
            title: Text(h.alias),
            subtitle: Text('${h.user}@${h.address}:${h.port}'),
            trailing: StatusBadge(
              label: h.pushEnabled ? 'push' : 'no push',
              tone: h.pushEnabled ? BadgeTone.success : BadgeTone.neutral,
            ),
            onTap: () => onOpen(h),
          ),
      ],
    );
  }
}
