import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/themed_mole.dart';

/// Shown once pairing finished: the mole celebrates, then open the host.
class PairSuccessView extends StatelessWidget {
  const PairSuccessView({super.key, required this.alias, required this.onOpen});

  final String alias;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => MoleMessage(
    title: context.l10n.pairedWith(alias),
    message: context.l10n.pairedBody,
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
