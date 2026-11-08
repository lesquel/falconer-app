import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/entities/notification_hours.dart';
import '../../../settings/presentation/views/notification_hours_tile.dart';
import '../../../sessions/domain/entities/remote_session.dart';
import '../../domain/entities/paired_device.dart';
import '../controllers/host_detail_controller.dart';
import '../controllers/paired_devices_controller.dart';
import '../views/host_detail_view.dart';
import '../views/paired_devices_view.dart';

class HostDetailContainer extends ConsumerWidget {
  const HostDetailContainer({super.key, required this.hostId});
  final String hostId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.deleteHostTitle),
        content: Text(l.deleteHostBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(hostConnectionsProvider).disconnect(hostId);
    await ref.read(manageHostsProvider).delete(hostId);
    if (context.mounted) context.go('/');
  }

  Future<bool> _confirmRevoke(BuildContext context, String alias, PairedDevice d) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(
            d.isThisPhone
                ? context.l10n.revokeThisPhoneTitle
                : context.l10n.revokeDeviceTitle(d.name),
          ),
          content: Text(
            d.isThisPhone
                ? context.l10n.revokeThisPhoneBody(alias)
                : context.l10n.revokeDeviceBody(alias),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: Text(context.l10n.cancel)),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(context.l10n.revoke)),
          ],
        ),
      ) ==
      true;

  Future<void> _revoke(BuildContext context, WidgetRef ref, String alias, PairedDevice d) async {
    final outcome = await ref
        .read(pairedDevicesControllerProvider(hostId).notifier)
        .revoke(d, confirm: (d) => _confirmRevoke(context, alias, d));
    if (!context.mounted) return;
    final l = context.l10n;
    final msg = switch (outcome) {
      RevokeOutcome.revoked => l.deviceRevoked(d.name),
      RevokeOutcome.revokedThisPhone => l.thisPhoneRevoked(alias),
      _ => null,
    };
    if (msg != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final host = ref.watch(hostProvider(hostId)).value;
    final state = ref.watch(hostDetailProvider(hostId));
    final ctrl = ref.read(hostDetailProvider(hostId).notifier);
    final devices = ref.watch(pairedDevicesControllerProvider(hostId));
    final settings = ref.watch(settingsProvider).value ?? const AppSettings();
    final devicesCtrl = ref.read(pairedDevicesControllerProvider(hostId).notifier);
    if (host == null) {
      return Scaffold(body: MoleMessage(title: context.l10n.openingHost, busy: true));
    }
    return Scaffold(
      body: HostDetailView(
        host: host,
        sessions: state.sessions,
        agents: state.agents,
        loading: state.loading,
        error: state.error == null
            ? null
            : SizedBox(
                height: 320,
                child: FailurePanel(failure: state.error!, onRetry: ctrl.load),
              ),
        devices: PairedDevicesView(
          devices: devices.devices,
          loading: devices.loading,
          error: devices.error == null
              ? null
              : SizedBox(
                  height: 320,
                  child: FailurePanel(failure: devices.error!, onRetry: devicesCtrl.load),
                ),
          onLoad: devicesCtrl.load,
          onRevoke: (d) => _revoke(context, ref, host.alias, d),
        ),
        onLoad: ctrl.load,
        onShell: () => context.push('/terminal/$hostId'),
        // The listed Herdr session, or the default one when not loaded yet.
        onHerdr: state.sessions != null && !state.sessions!.any((s) => s.kind == SessionKind.herdr)
            ? null
            : () => context.push(
                Uri(
                  path: '/terminal/$hostId',
                  queryParameters: {
                    'session':
                        state.sessions
                            ?.where((s) => s.kind == SessionKind.herdr)
                            .firstOrNull
                            ?.name ??
                        'default',
                    'kind': SessionKind.herdr.name,
                  },
                ).toString(),
              ),
        onAttach: (s) => context.push(
          Uri(
            path: '/terminal/$hostId',
            queryParameters: {'session': s.name, 'kind': s.kind.name},
          ).toString(),
        ),
        onEnablePush: () => ctrl.enablePush('Android phone'),
        onBack: () => context.canPop() ? context.pop() : context.go('/'),
        onEdit: () => context.push('/hosts/$hostId/edit'),
        onUsage: () => context.push('/hosts/$hostId/usage'),
        notificationHours: NotificationHoursTile(
          hours: settings.hostNotificationHours[hostId],
          inherited: () => settings.notificationHours,
          onChanged: (c) => unawaited(
            ref
                .read(settingsRepositoryProvider)
                .save(
                  settings.withHostNotificationHours(hostId, switch (c) {
                    // "Always" for one host is an all-day window, so it
                    // overrides an app-wide window.
                    SetHours(:final hours) => hours ?? const NotificationHours(0, 0),
                    InheritHours() => null,
                  }),
                ),
          ),
        ),
        onDelete: () => _delete(context, ref),
      ),
    );
  }
}
