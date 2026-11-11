/// Herdr session state as `openmosh-hook herdr snapshot|read` reports it.
/// Host-provided values are validated here: ids must match the hook's
/// validators (entries with bad ids are dropped) and text is cleaned.
library;

import '../../../../shared/domain/display_text.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';

enum HerdrStatus { working, blocked, done, idle, unknown }

HerdrStatus _status(Object? raw) =>
    HerdrStatus.values.where((s) => s.name == raw).firstOrNull ?? HerdrStatus.unknown;

const _protocol = HookFailure('protocol', 'openmosh-hook returned unexpected output.');

final class HerdrWorkspace {
  const HerdrWorkspace({required this.id, required this.label, this.focused = false});
  final String id;
  final String label;
  final bool focused;
}

final class HerdrTab {
  const HerdrTab({
    required this.id,
    required this.workspaceId,
    required this.label,
    this.number = 0,
    this.status = HerdrStatus.unknown,
    this.paneCount = 0,
    this.focused = false,
  });
  final String id;
  final String workspaceId;
  final String label;
  final int number;
  final HerdrStatus status;
  final int paneCount;
  final bool focused;
}

final class HerdrPane {
  const HerdrPane({
    required this.id,
    required this.tabId,
    required this.workspaceId,
    this.agent,
    this.status = HerdrStatus.unknown,
    this.focused = false,
  });
  final String id;
  final String tabId;
  final String workspaceId;

  /// Agent id Herdr detected in the pane (`claude`, `codex` …); null for a shell.
  final String? agent;
  final HerdrStatus status;
  final bool focused;
}

final class HerdrSnapshot {
  const HerdrSnapshot({this.workspaces = const [], this.tabs = const [], this.panes = const []});
  final List<HerdrWorkspace> workspaces;
  final List<HerdrTab> tabs;
  final List<HerdrPane> panes;

  List<HerdrTab> tabsOf(String workspaceId) =>
      tabs.where((t) => t.workspaceId == workspaceId).toList();

  List<HerdrPane> panesOf(String tabId) => panes.where((p) => p.tabId == tabId).toList();

  HerdrPane? pane(String id) => panes.where((p) => p.id == id).firstOrNull;

  /// The pane the computer shows: focused in the focused tab of the focused
  /// workspace, else any focused pane.
  HerdrPane? get focusedPane {
    final ws = workspaces.where((w) => w.focused).firstOrNull?.id;
    final tab = tabs.where((t) => t.focused && (ws == null || t.workspaceId == ws)).firstOrNull;
    return panes.where((p) => p.focused && (tab == null || p.tabId == tab.id)).firstOrNull ??
        panes.where((p) => p.focused).firstOrNull;
  }

  static HerdrSnapshot fromJson(Map<String, Object?> raw) {
    List<Map<String, Object?>> list(String k) => [
      for (final e in raw[k] is List ? raw[k]! as List : const [])
        ?(e is Map<String, Object?> ? e : null),
    ];
    String label(Object? v) => v is String ? sanitizeText(v, max: 64) : '';
    bool flag(Object? v) => v == true;
    int count(Object? v) => v is int && v >= 0 ? v : 0;
    bool target(Object? v) => v is String && isHerdrTargetId(v);
    return HerdrSnapshot(
      workspaces: [
        for (final w in list('workspaces'))
          if (target(w['id']))
            HerdrWorkspace(
              id: w['id']! as String,
              label: label(w['label']),
              focused: flag(w['focused']),
            ),
      ],
      tabs: [
        for (final t in list('tabs'))
          if (target(t['id']) && target(t['workspace_id']))
            HerdrTab(
              id: t['id']! as String,
              workspaceId: t['workspace_id']! as String,
              label: label(t['label']),
              number: count(t['number']),
              status: _status(t['agent_status']),
              paneCount: count(t['pane_count']),
              focused: flag(t['focused']),
            ),
      ],
      panes: [
        for (final p in list('panes'))
          if (p['id'] is String &&
              isHerdrPaneId(p['id']! as String) &&
              target(p['tab_id']) &&
              target(p['workspace_id']))
            HerdrPane(
              id: p['id']! as String,
              tabId: p['tab_id']! as String,
              workspaceId: p['workspace_id']! as String,
              agent: p['agent'] is String ? sanitizeText(p['agent']! as String, max: 32) : null,
              status: _status(p['agent_status']),
              focused: flag(p['focused']),
            ),
      ],
    );
  }
}

/// One pane's visible text, as `herdr read` returns it.
/// Most lines one `herdr read` returns (the hook's `--lines` cap).
const maxPaneReadLines = 2000;

final class PaneScreen {
  const PaneScreen({this.agent, this.status = HerdrStatus.unknown, this.lines = const []});
  final String? agent;
  final HerdrStatus status;
  final List<String> lines;

  /// Control and invisible formatting characters (bidi overrides …) are
  /// removed; leading spaces stay, the parser reads indentation.
  static final _invisible = RegExp(r'[\p{Cc}\p{Cf}\p{Zl}\p{Zp}]', unicode: true);

  static PaneScreen fromJson(Map<String, Object?> raw) {
    final lines = raw['lines'] is List ? raw['lines']! as List : const [];
    return PaneScreen(
      agent: raw['agent'] is String ? sanitizeText(raw['agent']! as String, max: 32) : null,
      status: _status(raw['agent_status']),
      lines: [
        for (final l in lines.take(maxPaneReadLines))
          if (l is String) truncateText(l.replaceAll(_invisible, ''), 1000),
      ],
    );
  }
}

/// A long-poll answer: [body] is null when the state still matched `since`.
final class Polled<T> {
  const Polled(this.rev, this.unchanged, this.body);
  final String rev;
  final bool unchanged;
  final T? body;

  static Polled<T> fromJson<T>(Object? raw, T Function(Map<String, Object?>) body) {
    if (raw is! Map<String, Object?>) throw _protocol;
    final rev = raw['rev'];
    if (rev is! String || !isHerdrRev(rev)) throw _protocol;
    final unchanged = raw['unchanged'] == true;
    return Polled(rev, unchanged, unchanged ? null : body(raw));
  }
}
