import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../herdr/presentation/views/herdr_status.dart';
import '../../domain/entities/screen_block.dart';
import '../../domain/usecases/agent_entries.dart';
import 'agent_entry_views.dart';
import 'permission_card.dart';

export 'permission_card.dart' show choiceQuestion, shortChoiceLabel;

/// The product name of an agent id Herdr reports; other titles stay as is.
String agentDisplayName(String id) => switch (id.toLowerCase()) {
  'claude' => 'Claude Code',
  'codex' => 'Codex',
  'gemini' => 'Gemini CLI',
  'cursor' => 'Cursor',
  'copilot' => 'GitHub Copilot',
  'kiro' => 'Kiro',
  'opencode' => 'OpenCode',
  'aider' => 'Aider',
  'amp' => 'Amp',
  'pi' => 'Pi',
  _ => id,
};

/// Graphic view of an agent's pane: each kind of output drawn differently, a
/// menu the agent waits on as big buttons, and a composer for the agent's
/// input line. Purely presentational.
class AgentScreenView extends StatelessWidget {
  const AgentScreenView({
    super.key,
    required this.title,
    required this.blocks,
    required this.loaded,
    required this.onKeys,
    required this.onRetry,
    required this.onTerminalMode,
    required this.composer,
    this.status = HerdrStatus.unknown,
    this.subtitle,
    this.error,
    this.onBack,
    this.onEnter,
    this.onLoadEarlier,
    this.loadingEarlier = false,
    this.onChoice,
  });

  final String title;

  /// Second header line: the Herdr session.
  final String? subtitle;
  final HerdrStatus status;
  final List<ScreenBlock> blocks;

  /// False until the first screen arrived.
  final bool loaded;
  final Object? error;
  final ValueChanged<List<String>> onKeys;

  /// Answers the docked menu with an option's keys; a non-null result is a
  /// failure. Null sends through [onKeys].
  final Future<Object?> Function(List<String> keys)? onChoice;
  final VoidCallback onRetry;
  final VoidCallback onTerminalMode;
  final VoidCallback? onBack;
  final Widget composer;

  /// The ↵ key; null presses Enter through [onKeys].
  final VoidCallback? onEnter;

  /// Reads earlier lines of the pane; null hides the action.
  final VoidCallback? onLoadEarlier;
  final bool loadingEarlier;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = MoshColors.of(context);
    final name = agentDisplayName(title);
    final draft = blocks.whereType<InputBlock>().map((b) => b.draft.trim()).firstOrNull ?? '';
    // The menu the agent waits on is docked above the composer, not in the
    // scrolling list (the parser emits at most one, at the bottom).
    final choice = blocks.whereType<ChoiceBlock>().lastOrNull;
    final shown = blocks.whereType<TextBlock>().toList();
    final Widget body;
    if (!loaded) {
      body = error != null
          ? FailurePanel(failure: error!, onRetry: onRetry)
          : const Center(child: CircularProgressIndicator());
    } else if (shown.isEmpty && choice != null) {
      body = const SizedBox.expand();
    } else if (shown.isEmpty) {
      body = Center(
        child: Text(l.agentViewEmpty, style: TextStyle(color: c.muted)),
      );
    } else {
      // Reversed: the newest output sits above the composer, like the terminal.
      // Built lazily: a long history makes hundreds of paragraphs, and only
      // the visible ones are created on each poll.
      final earlier = onLoadEarlier;
      body = ListView.builder(
        key: const Key('agent-blocks'),
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: shown.length + (earlier != null ? 1 : 0),
        itemBuilder: (context, index) {
          // Reversed list: the last item sits at the top.
          if (index == shown.length) {
            return Center(
              child: TextButton.icon(
                key: const Key('agent-load-earlier'),
                onPressed: loadingEarlier ? null : earlier,
                icon: loadingEarlier
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.history),
                label: Text(l.agentViewLoadEarlier),
              ),
            );
          }
          final i = shown.length - 1 - index;
          final b = shown[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AgentEntryView(entryFor(b), key: Key('text-${b.role.name}-$i')),
          );
        },
      );
    }
    return SafeArea(
      child: Column(
        children: [
          SizedBox(
            height: 60,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
              child: Row(
                children: [
                  if (onBack != null) ...[
                    CircleIconButton(icon: Icons.chevron_left, tooltip: l.back, onPressed: onBack),
                    const SizedBox(width: 10),
                  ],
                  _Monogram(name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.muted, fontSize: 12.5),
                          ),
                      ],
                    ),
                  ),
                  if (loaded) _StatusPill(status),
                  IconButton(
                    key: const Key('agent-terminal-mode'),
                    tooltip: l.herdrTerminalMode,
                    icon: const Icon(Icons.terminal),
                    onPressed: onTerminalMode,
                  ),
                ],
              ),
            ),
          ),
          if (loaded && error != null)
            Text(l.herdrOutOfDate, style: TextStyle(color: c.muted, fontSize: 12)),
          Expanded(child: body),
          // Up to two thirds of the space left (less with the keyboard up);
          // a taller card scrolls.
          if (loaded && choice != null)
            Flexible(
              flex: 2,
              child: Align(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: PermissionCard(
                    agent: name,
                    block: choice,
                    onChoice:
                        onChoice ??
                        (keys) async {
                          onKeys(keys);
                          return null;
                        },
                  ),
                ),
              ),
            ),
          _KeysRow(onKeys: onKeys, onEnter: onEnter),
          if (draft.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.agentViewDraft(draft),
                  key: const Key('agent-draft'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: 12),
                ),
              ),
            ),
          composer,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// The agent's initial on a tile.
class _Monogram extends StatelessWidget {
  const _Monogram(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return ExcludeSemantics(
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: c.surfaceHigh, borderRadius: BorderRadius.circular(10)),
        child: Text(
          name.isEmpty ? '?' : name.characters.first.toUpperCase(),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

/// The agent's state with an icon and a label, never color alone.
class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);
  final HerdrStatus status;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final (IconData icon, Color fg, Color? bg) = switch (status) {
      HerdrStatus.blocked => (Icons.notifications_active, c.onWarning, c.warning),
      HerdrStatus.working => (Icons.autorenew, c.foreground, c.surfaceHigh),
      HerdrStatus.done => (Icons.check, c.foreground, c.surfaceHigh),
      _ => (Icons.radio_button_unchecked, c.muted, null),
    };
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: bg == null ? Border.all(color: c.outline) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            HerdrStatusBadge.label(context.l10n, status),
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Keys for menus the parser left as text.
class _KeysRow extends StatelessWidget {
  const _KeysRow({required this.onKeys, this.onEnter});
  final ValueChanged<List<String>> onKeys;
  final VoidCallback? onEnter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget key(String name, String tooltip, Widget child, {VoidCallback? onPressed}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Tooltip(
          message: tooltip,
          child: TextButton(
            key: Key('agent-key-$name'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              padding: EdgeInsets.zero,
              foregroundColor: MoshColors.of(context).muted,
              textStyle: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onPressed ?? () => onKeys([name]),
            child: child,
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(9, 4, 9, 0),
      child: Row(
        children: [
          key('esc', l.herdrKeyEsc, Text(l.herdrKeyEsc)),
          key('up', l.herdrKeyUp, const Icon(Icons.keyboard_arrow_up)),
          key('down', l.herdrKeyDown, const Icon(Icons.keyboard_arrow_down)),
          key('tab', l.herdrKeyTab, Text(l.herdrKeyTab)),
          key('enter', l.herdrKeyEnter, const Icon(Icons.keyboard_return), onPressed: onEnter),
        ],
      ),
    );
  }
}
