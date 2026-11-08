import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/agent_usage.dart';
import 'usage_format.dart';

/// Periods offered by the switch, in days.
const usagePeriods = [1, 7, 30];

/// "Agent usage": tokens per agent, plan limits first when the agent
/// recorded them, then top projects and models.
class UsageView extends StatelessWidget {
  const UsageView({
    super.key,
    required this.days,
    required this.report,
    required this.loading,
    required this.onDays,
    required this.onRefresh,
    this.error,
    this.onBack,
    this.now,
  });

  final int days;
  final UsageReport? report;
  final bool loading;
  final Object? error;
  final ValueChanged<int> onDays;
  final Future<void> Function() onRefresh;
  final VoidCallback? onBack;

  /// Clock for reset times; defaults to the report time, then now.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final r = report;
    final shown = r?.days ?? days;
    final clock = now ?? DateTime.now();
    final available = [...?r?.agents.where((a) => a.available)];
    final missing = [...?r?.agents.where((a) => !a.available)];
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                if (onBack != null)
                  CircleIconButton(icon: Icons.chevron_left, tooltip: l.back, onPressed: onBack),
                const Spacer(),
                IconButton(
                  tooltip: l.refresh,
                  icon: const Icon(Icons.refresh),
                  onPressed: loading ? null : onRefresh,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.agentUsage,
                      style: t.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        letterSpacing: -1,
                        color: c.foreground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l.usageSubtitle, style: t.bodyMedium?.copyWith(color: c.muted)),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Semantics(
              label: l.usagePeriod,
              child: SegmentedButton<int>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(minimumSize: const Size(0, 48)),
                segments: [
                  for (final d in usagePeriods)
                    ButtonSegment(value: d, label: Text(l.usageDays(d))),
                ],
                selected: {days},
                onSelectionChanged: loading ? null : (s) => onDays(s.first),
              ),
            ),
            const SizedBox(height: 14),
            if (loading && r == null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(l.usageLoading, style: TextStyle(color: c.muted)),
                  ],
                ),
              )
            else if (loading)
              const LinearProgressIndicator(minHeight: 2),
            if (error != null)
              SizedBox(
                height: 320,
                child: FailurePanel(failure: error!, onRetry: loading ? null : onRefresh),
              ),
            if (r != null && error == null) ...[
              if (available.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l.usageEmpty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.muted),
                  ),
                ),
              for (final a in available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AgentCard(usage: a, days: shown, now: r.generatedAt ?? clock),
                ),
              if (missing.isNotEmpty) _NotRecorded(agents: missing),
            ],
          ],
        ),
      ),
    );
  }
}

String _decimal(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'es' ? ',' : '.';

class _AgentCard extends StatelessWidget {
  const _AgentCard({required this.usage, required this.days, required this.now});
  final AgentUsage usage;
  final int days;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final dec = _decimal(context);
    String n(int v) => compactTokens(v, decimal: dec);
    final p = usage.period;
    return MoshTile(
      radius: MoshRadii.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            agentDisplayName(usage.agent),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.foreground),
          ),
          if (usage.note != null) ...[
            const SizedBox(height: 4),
            Text(usage.note!, style: TextStyle(fontSize: 13, color: c.muted)),
          ],
          if (usage.limits.isNotEmpty) ...[
            _Label(l.usagePlanLimits),
            for (final limit in usage.limits) _LimitBar(limit: limit, now: now),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Stat(label: l.today, value: n(usage.today.total)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Stat(label: l.usagePeriodTotal(days), value: n(p.total)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.usageBreakdown(n(p.input), n(p.output), n(p.cache)),
            style: TextStyle(fontSize: 13, color: c.muted),
          ),
          if (usage.projects.isNotEmpty) ...[
            _Label(l.usageProjects),
            ..._bars([for (final x in usage.projects) (x.project, x.tokens.total)], n),
          ],
          if (usage.models.isNotEmpty) ...[
            _Label(l.usageModels),
            ..._bars([for (final x in usage.models) (x.model, x.tokens.total)], n),
          ],
        ],
      ),
    );
  }

  static Iterable<Widget> _bars(List<(String, int)> rows, String Function(int) n) {
    final max = rows.fold(0, (m, r) => r.$2 > m ? r.$2 : m);
    return [
      for (final (name, tokens) in rows)
        _BarRow(name: name, value: n(tokens), fraction: max == 0 ? 0 : tokens / max),
    ];
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 6),
    child: Text(
      text,
      style: Theme.of(context).textTheme.labelLarge
          ?.copyWith(color: MoshColors.of(context).muted, fontWeight: FontWeight.w700),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return MoshTile(
      tone: TileTone.raised,
      radius: MoshRadii.key,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: c.foreground),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: c.muted),
          ),
        ],
      ),
    );
  }
}

class _LimitBar extends StatelessWidget {
  const _LimitBar({required this.limit, required this.now});
  final PlanLimit limit;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    final pct = limit.usedPercent.clamp(0, 100).toDouble();
    final pctText = pct.toStringAsFixed(pct == pct.roundToDouble() ? 0 : 1);
    final used = l.usagePercentUsed(pctText.replaceFirst('.', _decimal(context)));
    final resets = limit.resetsAt;
    final left = resets?.difference(now);
    final resetText = left == null
        ? null
        : left.inMinutes < 1
        ? l.usageResetsSoon
        : l.usageResetsIn(shortDuration(left));
    final color = pct >= 90 ? c.danger : c.accent;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: [limit.name, used, ?resetText].join(', '),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    limit.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w700, color: c.foreground),
                  ),
                ),
                Text(
                  used,
                  style: TextStyle(fontWeight: FontWeight.w800, color: c.foreground),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 10,
                color: color,
                backgroundColor: c.surfaceHigh,
              ),
            ),
            if (resetText != null) ...[
              const SizedBox(height: 4),
              Text(resetText, style: TextStyle(fontSize: 12, color: c.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.name, required this.value, required this.fraction});
  final String name;
  final String value;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.foreground),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: TextStyle(fontWeight: FontWeight.w700, color: c.foreground),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0, 1).toDouble(),
              minHeight: 6,
              color: c.foreground,
              backgroundColor: c.surfaceHigh,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotRecorded extends StatelessWidget {
  const _NotRecorded({required this.agents});
  final List<AgentUsage> agents;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    return MoshTile(
      radius: MoshRadii.tile,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: c.muted,
          collapsedIconColor: c.muted,
          title: Text(
            l.usageNotRecorded(agents.length),
            style: TextStyle(fontWeight: FontWeight.w700, color: c.muted),
          ),
          subtitle: Text(l.usageNotRecordedHint, style: TextStyle(fontSize: 12, color: c.muted)),
          children: [
            for (final a in agents)
              ListTile(
                title: Text(agentDisplayName(a.agent), style: TextStyle(color: c.muted)),
                subtitle: a.note == null ? null : Text(a.note!, style: TextStyle(color: c.muted)),
              ),
          ],
        ),
      ),
    );
  }
}
