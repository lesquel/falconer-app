import 'package:flutter/material.dart';

import '../../../../shared/ui/molecules/themed_mole.dart';

/// Shown once pairing finished: the mole celebrates, then open the host.
class PairSuccessView extends StatelessWidget {
  const PairSuccessView({super.key, required this.alias, required this.onOpen});

  final String alias;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => MoleMessage(
    title: 'Paired with $alias',
    message: 'Its SSH host key is pinned and notifications are encrypted end to end.',
    size: 180,
    actions: [
      FilledButton.icon(
        key: const Key('open_paired_host'),
        onPressed: onOpen,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Open host'),
      ),
    ],
  );
}
