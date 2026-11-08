import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/usage/domain/entities/agent_usage.dart';

Object? fixture() => jsonDecode(File('test/fixtures/usage/usage_report.json').readAsStringSync());

void main() {
  test('parses the usage contract', () {
    final r = UsageReport.fromJson(fixture());
    expect(r.days, 7);
    expect(r.generatedAt, DateTime.fromMillisecondsSinceEpoch(1794168000 * 1000, isUtc: true));
    expect(r.agents.map((a) => a.agent), ['claude', 'codex', 'opencode']);

    final claude = r.agents[0];
    expect(claude.available, isTrue);
    expect(claude.note, isNull);
    expect(claude.today.total, 1200000);
    expect(claude.period.input, 850000);
    expect(claude.period.output, 150000);
    expect(claude.period.cacheRead, 7000000);
    expect(claude.period.cacheWrite, 400000);
    expect(claude.period.total, 8400000);
    expect(claude.projects.map((p) => (p.project, p.tokens.total)), [
      ('OpenMosh', 6000000),
      ('dotfiles', 2400000),
    ]);
    expect(claude.models.single.model, 'claude-opus');
    expect(claude.limits, isEmpty);

    final codex = r.agents[1];
    expect(codex.limits.map((l) => (l.name, l.usedPercent, l.windowMinutes)), [
      ('5h', 42.0, 300),
      ('weekly', 7.0, 10080),
    ]);
    expect(
      codex.limits[0].resetsAt,
      DateTime.fromMillisecondsSinceEpoch(1794175200 * 1000, isUtc: true),
    );
    expect(codex.limits[1].resetsAt, isNull);

    final opencode = r.agents[2];
    expect(opencode.available, isFalse);
    expect(opencode.note, 'No local usage logs.');
  });

  test('skips malformed entries and tolerates missing or odd numbers', () {
    final r = UsageReport.fromJson({
      'days': 7.0,
      'agents': [
        'nope',
        {'available': true},
        {'agent': '', 'available': true},
        {
          'agent': 'claude',
          'available': true,
          'today': {'input': 10.0, 'output': 5, 'total': 'x'},
          'period': 'bad',
          'projects': [
            {
              'project': 'ok',
              'tokens': {'total': 3},
            },
            {
              'project': 7,
              'tokens': {'total': 3},
            },
            {
              'tokens': {'total': 3},
            },
            null,
          ],
          'models': 'bad',
          'limits': [
            {'name': '5h', 'used_percent': 'x'},
            {'used_percent': 10},
            {'name': 'week', 'used_percent': 12.5, 'window_minutes': 'x', 'resets_at': 'soon'},
          ],
        },
      ],
    });
    expect(r.days, 7);
    expect(r.generatedAt, isNull);
    final a = r.agents.single;
    expect(a.agent, 'claude');
    expect(a.today.input, 10);
    expect(a.today.output, 5);
    expect(a.today.total, 15, reason: 'a missing total is the sum of the parts');
    expect(a.period.total, 0);
    expect(a.projects.map((p) => p.project), ['ok']);
    expect(a.models, isEmpty);
    expect(a.limits.single.name, 'week');
    expect(a.limits.single.windowMinutes, isNull);
    expect(a.limits.single.resetsAt, isNull);
  });

  test('a non-object report has no agents', () {
    expect(UsageReport.fromJson(null).agents, isEmpty);
    expect(UsageReport.fromJson([1, 2]).agents, isEmpty);
  });

  test('available defaults to false when not true', () {
    final r = UsageReport.fromJson({
      'agents': [
        {'agent': 'gemini'},
      ],
    });
    expect(r.agents.single.available, isFalse);
  });
}
