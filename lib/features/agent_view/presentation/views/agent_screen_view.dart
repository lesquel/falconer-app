import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../herdr/presentation/views/herdr_status.dart';
import '../../domain/entities/screen_block.dart';
import 'permission_card.dart';

export 'permission_card.dart' show shortChoiceLabel;

/// Graphic view of an agent's pane: text as readable cards, a menu the agent
/// waits on as big buttons, and a composer for the agent's input line.
/// Purely presentational.
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
    this.error,
    this.onBack,
    this.onEnter,
    this.onLoadEarlier,
    this.loadingEarlier = false,
    this.onChoice,
  });

  final String title;
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
      body = ListView(
        key: const Key('agent-blocks'),
        reverse: true,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        children: [
          for (final (i, b) in shown.indexed.toList().reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TextCard(b.text, role: b.role, key: Key('text-${b.role.name}-$i')),
            ),
          // Reversed list: the last child sits at the top.
          if (onLoadEarlier != null)
            Center(
              child: TextButton.icon(
                key: const Key('agent-load-earlier'),
                onPressed: loadingEarlier ? null : onLoadEarlier,
                icon: loadingEarlier
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.history),
                label: Text(l.agentViewLoadEarlier),
              ),
            ),
        ],
      );
    }
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                if (onBack != null) ...[
                  CircleIconButton(icon: Icons.chevron_left, tooltip: l.back, onPressed: onBack),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                ),
                if (loaded) HerdrStatusBadge(status),
                IconButton(
                  key: const Key('agent-terminal-mode'),
                  tooltip: l.herdrTerminalMode,
                  icon: const Icon(Icons.terminal),
                  onPressed: onTerminalMode,
                ),
              ],
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
                    agent: title,
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

/// Output that looks like code, a table or a tree keeps its columns.
bool looksLikeCode(String text) {
  final lines = text.split('\n');
  return lines.any(
    (l) =>
        l.startsWith('  ') ||
        RegExp(r'[{};]\s*$|^\s*[$#>] |[│├└─┌┐┘]|^\s*(\d+\s*[|:]|[+-]{1}\s)').hasMatch(l),
  );
}

/// A paragraph by who wrote it: the user's prompt as a right-aligned accent
/// bubble, the agent's reply as a left card, a tool run as a monospace card.
class _TextCard extends StatelessWidget {
  const _TextCard(this.text, {super.key, required this.role});
  final String text;
  final TextRole role;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.3);
    const prose = TextStyle(fontSize: 15, height: 1.35);
    Widget card(Color color, TextStyle style, BorderRadius radius) => Material(
      color: color,
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText(text, style: style),
      ),
    );
    final radius = BorderRadius.circular(MoshRadii.key);
    const tail = Radius.circular(4);
    return switch (role) {
      TextRole.user => Padding(
        padding: const EdgeInsets.only(left: 48),
        child: Align(
          alignment: Alignment.centerRight,
          child: card(
            c.accent,
            prose.copyWith(color: c.onAccent),
            radius.copyWith(bottomRight: tail),
          ),
        ),
      ),
      TextRole.agent => Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: looksLikeCode(text)
              ? card(c.surfaceHigh, mono, radius)
              : card(c.surface, prose, radius.copyWith(bottomLeft: tail)),
        ),
      ),
      TextRole.tool => card(c.surfaceHigh, mono, radius),
    };
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
          child: OutlinedButton(
            key: Key('agent-key-$name'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              padding: EdgeInsets.zero,
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
