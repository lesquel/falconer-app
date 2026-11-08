/// Token usage per agent reported by `openmosh-hook usage --json`.
///
/// Parsing is tolerant: malformed entries are skipped, numbers may arrive as
/// int or double, and missing token counts are zero.
library;

/// Token counts of one bucket (a day, a period, a project or a model).
final class TokenCounts {
  const TokenCounts({
    this.input = 0,
    this.output = 0,
    this.cacheRead = 0,
    this.cacheWrite = 0,
    this.total = 0,
  });

  static const zero = TokenCounts();

  final int input;
  final int output;
  final int cacheRead;
  final int cacheWrite;

  /// Sum of the parts; the hook sends it, and it is computed when missing.
  final int total;

  int get cache => cacheRead + cacheWrite;

  static TokenCounts fromJson(Object? raw) {
    if (raw is! Map) return zero;
    final input = _count(raw['input']) ?? 0;
    final output = _count(raw['output']) ?? 0;
    final cacheRead = _count(raw['cache_read']) ?? 0;
    final cacheWrite = _count(raw['cache_write']) ?? 0;
    return TokenCounts(
      input: input,
      output: output,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
      total: _count(raw['total']) ?? input + output + cacheRead + cacheWrite,
    );
  }
}

/// Tokens spent in one project (the last folder of the agent's cwd).
final class ProjectUsage {
  const ProjectUsage(this.project, this.tokens);
  final String project;
  final TokenCounts tokens;

  static ProjectUsage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = _text(raw['project']);
    return name == null ? null : ProjectUsage(name, TokenCounts.fromJson(raw['tokens']));
  }
}

/// Tokens spent with one model.
final class ModelUsage {
  const ModelUsage(this.model, this.tokens);
  final String model;
  final TokenCounts tokens;

  static ModelUsage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = _text(raw['model']);
    return name == null ? null : ModelUsage(name, TokenCounts.fromJson(raw['tokens']));
  }
}

/// A plan usage limit the agent wrote to its local logs (for example
/// Codex's 5-hour and weekly windows).
final class PlanLimit {
  const PlanLimit({
    required this.name,
    required this.usedPercent,
    this.windowMinutes,
    this.resetsAt,
  });

  final String name;
  final double usedPercent;
  final int? windowMinutes;
  final DateTime? resetsAt;

  static PlanLimit? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final name = _text(raw['name']);
    final used = raw['used_percent'];
    if (name == null || used is! num || !used.isFinite) return null;
    return PlanLimit(
      name: name,
      usedPercent: used.toDouble(),
      windowMinutes: _count(raw['window_minutes']),
      resetsAt: _time(raw['resets_at']),
    );
  }
}

final class AgentUsage {
  const AgentUsage({
    required this.agent,
    required this.available,
    this.note,
    this.today = TokenCounts.zero,
    this.period = TokenCounts.zero,
    this.projects = const [],
    this.models = const [],
    this.limits = const [],
  });

  /// Agent id as the hook names it (`claude`, `codex`, …).
  final String agent;

  /// False when the hook has no local logs to read for this agent.
  final bool available;
  final String? note;
  final TokenCounts today;
  final TokenCounts period;
  final List<ProjectUsage> projects;
  final List<ModelUsage> models;
  final List<PlanLimit> limits;

  static AgentUsage? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final agent = _text(raw['agent']);
    if (agent == null) return null;
    return AgentUsage(
      agent: agent,
      available: raw['available'] == true,
      note: _text(raw['note']),
      today: TokenCounts.fromJson(raw['today']),
      period: TokenCounts.fromJson(raw['period']),
      projects: _list(raw['projects'], ProjectUsage.fromJson),
      models: _list(raw['models'], ModelUsage.fromJson),
      limits: _list(raw['limits'], PlanLimit.fromJson),
    );
  }
}

final class UsageReport {
  const UsageReport({this.days, this.generatedAt, this.agents = const []});

  /// The period the hook actually used; null when it did not say.
  final int? days;
  final DateTime? generatedAt;
  final List<AgentUsage> agents;

  static UsageReport fromJson(Object? raw) {
    if (raw is! Map) return const UsageReport();
    return UsageReport(
      days: _count(raw['days']),
      generatedAt: _time(raw['generated_at']),
      agents: _list(raw['agents'], AgentUsage.fromJson),
    );
  }
}

List<T> _list<T extends Object>(Object? raw, T? Function(Object?) parse) =>
    raw is List ? raw.map(parse).nonNulls.toList() : <T>[];

/// A non-negative whole number from an int or a finite double.
int? _count(Object? v) => v is num && v.isFinite && v >= 0 ? v.toInt() : null;

String? _text(Object? v) => v is String && v.trim().isNotEmpty ? v : null;

DateTime? _time(Object? v) {
  final s = _count(v);
  return s == null ? null : DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true);
}
