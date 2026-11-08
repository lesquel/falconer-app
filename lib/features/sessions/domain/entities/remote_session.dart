/// Herdr/tmux sessions and agents reported by `openmosh-hook`.
library;

import '../../../../shared/domain/display_text.dart';
import '../../../../shared/domain/posix_shell.dart';

enum SessionKind { herdr, tmux }

enum AgentState { idle, working, blocked, done, unknown }

final _name = RegExp(r'^[A-Za-z0-9._:@%+=-]{1,128}$');

const _herdrAttachScript =
    r'h=$(command -v openmosh-hook || echo "$HOME/.local/bin/openmosh-hook"); '
    r'if [ -x "$h" ]; then exec "$h" attach herdr --session "$1"; fi; '
    r'exec herdr session attach "$1"';

final class RemoteSession {
  const RemoteSession({
    required this.name,
    required this.kind,
    this.attached = false,
    this.windows,
  });

  final String name;
  final SessionKind kind;
  final bool attached;
  final int? windows;

  /// Shell command typed into the PTY to (re)attach this session.
  ///
  /// Herdr goes through `openmosh-hook attach herdr`, which mirrors navigation
  /// so the computer follows the phone; without the hook it runs Herdr directly.
  /// The logic runs in `sh -c` (name passed as `$1`) so it works under any login
  /// shell, including fish.
  String get attachCommand => switch (kind) {
    SessionKind.herdr => shJoin(['sh', '-c', _herdrAttachScript, 'sh', name]),
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
  const AgentInfo({
    required this.paneId,
    required this.agent,
    required this.state,
    this.title,
    this.cwd,
  });

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
    final status = raw['status'] ?? raw['agent_status'] ?? raw['state'];
    final state =
        AgentState.values.where((s) => s.name == status).firstOrNull ?? AgentState.unknown;
    // Host-provided text: shown on screen, so stripped of bidi and controls.
    String? s(String k) => raw[k] is String ? sanitizeText(raw[k]! as String, max: 200) : null;
    return AgentInfo(
      paneId: sanitizeText(pane, max: 128),
      agent: sanitizeText(agent, max: 64),
      state: state,
      title: s('terminal_title_stripped') ?? s('title'),
      cwd: s('cwd'),
    );
  }
}
