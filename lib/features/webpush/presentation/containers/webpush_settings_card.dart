import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../domain/entities/webpush_registration.dart';
import '../controllers/webpush_controller.dart';
import '../containers/webpush_container.dart';
import '../views/webpush_view.dart';

/// Settings entry for notifications through the Falconer web app (the way
/// to get notifications on iOS and macOS, and an alternative on Android).
class WebPushSettingsCard extends ConsumerStatefulWidget {
  const WebPushSettingsCard({super.key});

  @override
  ConsumerState<WebPushSettingsCard> createState() => _State();
}

class _State extends ConsumerState<WebPushSettingsCard> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _review() {
    try {
      final raw = _code.text.trim();
      WebPushRegistration.parse(raw);
      setState(() => _error = null);
      _code.clear();
      context.push(webPushRoute, extra: WebPushCode(raw));
    } catch (e) {
      setState(() => _error = context.l10n.failureText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = ref.watch(webPushControllerProvider);
    final reg = st.registration;
    final hosts = (ref.watch(hostsProvider).value ?? const []).where((h) => h.paired);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MoshTile(
        key: const Key('webpush_card'),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications_active_outlined),
              title: Text(l.webPushTitle),
              subtitle: Text(
                reg == null ? l.webPushStatusOff : l.webPushStatusOn(reg.serviceHost),
                key: const Key('webpush_status'),
              ),
            ),
            if (reg != null)
              for (final h in hosts)
                ListTile(
                  dense: true,
                  leading: Icon(webPushHostIcon(st.statusOf(h.id))),
                  title: Text(webPushHostText(l, (alias: h.alias, status: st.statusOf(h.id)))),
                ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l.webPushExplain),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                key: const Key('webpush_code'),
                controller: _code,
                autocorrect: false,
                enableSuggestions: false,
                maxLines: 1,
                decoration: InputDecoration(
                  hintText: l.webPushPasteHint,
                  errorText: _error,
                  suffixIcon: IconButton(
                    key: const Key('webpush_review'),
                    tooltip: l.webPushReview,
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: _review,
                  ),
                ),
                onSubmitted: (_) => _review(),
              ),
            ),
            if (reg != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: TextButton(
                  key: const Key('webpush_off'),
                  onPressed: st.busy
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await ref.read(webPushControllerProvider.notifier).turnOff();
                          messenger.showSnackBar(SnackBar(content: Text(l.webPushTurnedOff)));
                        },
                  child: Text(l.webPushTurnOff),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
