import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/status_badge.dart';
import '../../domain/entities/herdr_snapshot.dart';

/// Agent status as a labelled badge: "needs you" stands out, the label always
/// names the state so color is never the only signal.
class HerdrStatusBadge extends StatelessWidget {
  const HerdrStatusBadge(this.status, {super.key});
  final HerdrStatus status;

  static String label(AppLocalizations l, HerdrStatus s) => switch (s) {
    HerdrStatus.blocked => l.herdrStatusBlocked,
    HerdrStatus.working => l.agentStateWorking,
    HerdrStatus.done => l.agentStateDone,
    HerdrStatus.idle => l.agentStateIdle,
    HerdrStatus.unknown => l.agentStateUnknown,
  };

  @override
  Widget build(BuildContext context) => StatusBadge(
    label: label(context.l10n, status),
    tone: switch (status) {
      HerdrStatus.blocked => BadgeTone.attention,
      HerdrStatus.working => BadgeTone.success,
      _ => BadgeTone.neutral,
    },
  );
}
