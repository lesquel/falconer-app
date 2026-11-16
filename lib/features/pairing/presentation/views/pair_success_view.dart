import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/themed_falcon.dart';

/// Shown once pairing finished: the falcon celebrates, then open the host.
class PairSuccessView extends StatelessWidget {
  const PairSuccessView({
    super.key,
    required this.alias,
    required this.onOpen,
    this.pushEnabled = true,
  });

  final String alias;
  final VoidCallback onOpen;

  /// False when the phone paired without notifications.
  final bool pushEnabled;

  @override
  Widget build(BuildContext context) => FalconMessage(
    title: context.l10n.pairedWith(alias),
    message: pushEnabled ? context.l10n.pairedBody : context.l10n.pairedWithoutPush,
    size: 180,
    actions: [
      FilledButton.icon(
        key: const Key('open_paired_host'),
        onPressed: onOpen,
        icon: const Icon(Icons.arrow_forward),
        label: Text(context.l10n.openHost),
      ),
    ],
  );
}
