import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../controllers/webpush_controller.dart';

/// One host line: alias and where the registration stands.
typedef WebPushHostLine = ({String alias, WebPushHostStatus status});

String webPushHostText(AppLocalizations l, WebPushHostLine h) => switch (h.status) {
  WebPushHostStatus.delivered => l.webPushHostDelivered(h.alias),
  WebPushHostStatus.pending => l.webPushHostPending(h.alias),
  WebPushHostStatus.hookTooOld => l.webPushHostTooOld(h.alias),
};

IconData webPushHostIcon(WebPushHostStatus s) => switch (s) {
  WebPushHostStatus.delivered => Icons.check_circle_outline,
  WebPushHostStatus.pending => Icons.schedule,
  WebPushHostStatus.hookTooOld => Icons.system_update_alt,
};

/// Confirmation screen for a pasted registration code: the push service host
/// it points at (never the keys), a warning that it replaces the current
/// destination, the confirm button, then the per-host results.
class WebPushView extends StatelessWidget {
  const WebPushView({
    super.key,
    required this.serviceHost,
    required this.busy,
    required this.hosts,
    required this.onConfirm,
    required this.onClose,
    this.error,
  });

  /// Push service host, e.g. `web.push.apple.com`; `null` when the code is invalid.
  final String? serviceHost;
  final bool busy;

  /// `null` until the registration was sent.
  final List<WebPushHostLine>? hosts;
  final VoidCallback onConfirm;
  final VoidCallback onClose;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sent = hosts;
    return ThumbPage(
      title: Text(l.webPushScreenTitle),
      onBack: onClose,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MoshTile(
              key: const Key('webpush_error'),
              child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ),
        if (serviceHost != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MoshTile(
              child: ListTile(
                key: const Key('webpush_service'),
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l.webPushServiceLabel),
                subtitle: Text(serviceHost!),
              ),
            ),
          ),
          if (sent == null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l.webPushDestination(serviceHost!),
                key: const Key('webpush_destination'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.webPushReplaces, key: const Key('webpush_replaces')),
            ),
            Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(l.webPushConfirmBody)),
            FilledButton(
              key: const Key('webpush_confirm'),
              onPressed: busy ? null : onConfirm,
              child: busy ? Text(l.webPushSending) : Text(l.webPushUse),
            ),
          ] else ...[
            if (sent.isEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(l.webPushNoHosts)),
            for (final h in sent)
              ListTile(
                key: Key('webpush_result_${h.alias}'),
                leading: Icon(webPushHostIcon(h.status)),
                title: Text(webPushHostText(l, h)),
              ),
            const SizedBox(height: 12),
            FilledButton(
              key: const Key('webpush_done'),
              onPressed: onClose,
              child: Text(l.webPushDone),
            ),
          ],
        ] else
          OutlinedButton(onPressed: onClose, child: Text(l.close)),
      ],
    );
  }
}
