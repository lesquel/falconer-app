/// Herdr/tmux sessions and agents reported by `openmosh-hook`.
library;

import '../../../../shared/domain/posix_shell.dart';

enum SessionKind { herdr, tmux }

enum AgentState { idle, working, blocked, done, unknown }

final _name = RegExp(r'^[A-Za-z0-9._:@%+=-]{1,128}$');

final class RemoteSession {
  const RemoteSession({required this.name, required this.kind, this.attached = false, this.windows});

  final String name;
  final SessionKind kind;
  final bool attached;
  final int? windows;

  /// Shell command typed into the PTY to (re)attach this session.
  String get attachCommand => switch (kind) {
        SessionKind.herdr => shJoin(['herdr', 'session', 'attach', name]),
        SessionKind.tmux => shJoin(['tmux', 'new-session', '-A', '-s', name]),
      };

  static RemoteSession? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final name = raw['name'];
    final kind = switch (raw['kind'] ?? raw['source'] ?? raw['runtime']) {
      'herdr' => SessionKind.herdr,
      'tmux' => SessionKind.tmux,
      _ => null,
    };
    if (name is! String || !_name.hasMatch(name) || kind == null) return null;
    final w = raw['windows'];
    return RemoteSession(
      name: name,
      kind: kind,
      attached: raw['attached'] == true,
      windows: w is int ? w : null,
    );
  }
}

final class AgentInfo {
  const AgentInfo({required this.paneId, required this.agent, required this.state, this.title, this.cwd});

  final String paneId;
  final String agent;
  final AgentState state;
  final String? title;
  final String? cwd;

  static AgentInfo? fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return null;
    final pane = raw['pane_id'] ?? raw['pane'];
    final agent = raw['agent'];
    if (pane is! String || agent is! String) return null;
    final status = raw['agent_status'] ?? raw['state'];
    final state = AgentState.values.where((s) => s.name == status).firstOrNull ?? AgentState.unknown;
    String? s(String k) => raw[k] is String ? raw[k]! as String : null;
    return AgentInfo(
      paneId: pane,
      agent: agent,
      state: state,
      title: s('terminal_title_stripped') ?? s('title'),
      cwd: s('cwd'),
    );
  }
}
