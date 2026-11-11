/// The fixed set of Herdr actions the phone may ask the hook for
/// (`openmosh-hook herdr action`, body on stdin). Each factory validates its
/// arguments the way the hook does, so a bad request never leaves the phone.
library;

import 'dart:convert';

import '../../../../shared/domain/display_text.dart';
import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';

/// Agents `herdr agent start` can launch (the hook's allowlist; not Aider).
const startableAgents = [
  'claude',
  'codex',
  'gemini',
  'cursor',
  'copilot',
  'kiro',
  'opencode',
  'amp',
  'pi',
];

/// Key names `pane.keys` accepts.
const paneKeyNames = {
  'enter', 'esc', 'tab', 'space', 'backspace', 'up', 'down', 'left', 'right', 'y', 'n', //
  '1', '2', '3', '4', '5', '6', '7', '8', '9',
};

const maxPaneKeys = 8;
const maxPaneTextChars = 4000;

const _badId = ValidationFailure('Invalid identifier.');

final class HerdrAction {
  const HerdrAction._(this.op, this.fields);

  final String op;
  final Map<String, Object?> fields;

  factory HerdrAction.workspaceCreate([String? label]) =>
      HerdrAction._('workspace.create', {if (label != null) 'label': _label(label)});

  factory HerdrAction.workspaceRename(String id, String label) =>
      HerdrAction._('workspace.rename', {'id': _target(id), 'label': _label(label)});

  factory HerdrAction.workspaceClose(String id) =>
      HerdrAction._('workspace.close', {'id': _target(id)});

  factory HerdrAction.workspaceFocus(String id) =>
      HerdrAction._('workspace.focus', {'id': _target(id)});

  factory HerdrAction.tabCreate(String workspaceId, [String? label]) => HerdrAction._(
    'tab.create',
    {'workspace_id': _target(workspaceId), if (label != null) 'label': _label(label)},
  );

  factory HerdrAction.tabRename(String id, String label) =>
      HerdrAction._('tab.rename', {'id': _target(id), 'label': _label(label)});

  factory HerdrAction.tabClose(String id) => HerdrAction._('tab.close', {'id': _target(id)});

  factory HerdrAction.tabFocus(String id) => HerdrAction._('tab.focus', {'id': _target(id)});

  factory HerdrAction.paneFocus(String id) => HerdrAction._('pane.focus', {'id': _pane(id)});

  factory HerdrAction.agentStart(String paneId, String agent) {
    if (!startableAgents.contains(agent)) throw _badId;
    return HerdrAction._('agent.start', {'pane_id': _pane(paneId), 'agent': agent});
  }

  factory HerdrAction.paneKeys(String paneId, List<String> keys) {
    if (keys.isEmpty || keys.length > maxPaneKeys || !keys.every(paneKeyNames.contains)) {
      throw _badId;
    }
    return HerdrAction._('pane.keys', {'pane_id': _pane(paneId), 'keys': List.of(keys)});
  }

  /// Types [text] into the pane, then Enter when [submit].
  factory HerdrAction.paneText(String paneId, String text, {bool submit = true}) {
    if (text.trim().isEmpty) throw const ValidationFailure('Write a message first.');
    if (text.length > maxPaneTextChars) {
      throw const ValidationFailure('Message is longer than 4000 characters.');
    }
    return HerdrAction._('pane.text', {'pane_id': _pane(paneId), 'text': text, 'submit': submit});
  }

  /// The request JSON for the hook's stdin.
  List<int> toBytes() => utf8.encode(jsonEncode({'op': op, ...fields}));

  static String _target(String id) => isHerdrTargetId(id) ? id : throw _badId;

  static String _pane(String id) => isHerdrPaneId(id) ? id : throw _badId;

  static String _label(String raw) {
    final clean = sanitizeLabel(raw);
    if (clean == null || clean.isEmpty) {
      throw const ValidationFailure('Name must be 1–64 characters.');
    }
    return clean;
  }
}
