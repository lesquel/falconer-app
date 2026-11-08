import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/status_badge.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/paired_device.dart';

/// "Paired devices" section of the host screen (SEC-11).
class PairedDevicesView extends StatelessWidget {
  const PairedDevicesView({
    super.key,
    required this.devices,
    required this.loading,
    required this.onLoad,
    required this.onRevoke,
    this.error,
  });

  final List<PairedDevice>? devices;
  final bool loading;
  final Widget? error;
  final VoidCallback onLoad;
  final ValueChanged<PairedDevice> onRevoke;

  static String _date(DateTime at) {
    final l = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${l.year}-${two(l.month)}-${two(l.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final list = devices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionLabel('Paired devices'),
        if (list == null)
          OutlinedButton.icon(
            onPressed: loading ? null : onLoad,
            icon: const Icon(Icons.devices_outlined),
            label: const Text('Show paired devices'),
          ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          ),
        ?error,
        if (list != null && list.isEmpty)
          Text('No devices are paired with this host.', style: TextStyle(color: c.muted)),
        for (final d in list ?? const <PairedDevice>[])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MoshTile(
              padding: EdgeInsets.zero,
              radius: MoshRadii.tile,
              child: ListTile(
                leading: Icon(d.isThisPhone ? Icons.smartphone : Icons.devices_other_outlined),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        d.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (d.isThisPhone) ...[
                      const SizedBox(width: 8),
                      const StatusBadge(label: 'this phone', tone: BadgeTone.success),
                    ],
                  ],
                ),
                subtitle: Text(
                  'Paired ${_date(d.pairedAt)}${d.endpointStale ? ' · endpoint stale' : ''}',
                ),
                trailing: IconButton(
                  tooltip: 'Revoke ${d.name}',
                  icon: Icon(Icons.link_off, color: c.danger),
                  onPressed: loading ? null : () => onRevoke(d),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
