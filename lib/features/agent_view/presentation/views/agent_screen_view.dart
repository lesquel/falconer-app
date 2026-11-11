import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/circle_icon_button.dart';
import '../../../../shared/ui/organisms/failure_panel.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../herdr/domain/entities/herdr_snapshot.dart';
import '../../../herdr/presentation/views/herdr_status.dart';
import '../../domain/entities/screen_block.dart';

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
  });

  final String title;
  final HerdrStatus status;
  final List<ScreenBlock> blocks;

  /// False until the first screen arrived.
  final bool loaded;
  final Object? error;
  final ValueChanged<List<String>> onKeys;
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
    final shown = blocks.where((b) => b is! InputBlock).toList();
    final Widget body;
    if (!loaded) {
      body = error != null
          ? FailurePanel(failure: error!, onRetry: onRetry)
          : const Center(child: CircularProgressIndicator());
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
              child: switch (b) {
                TextBlock(:final text, :final role) => _TextCard(
                  text,
                  role: role,
                  key: Key('text-${role.name}-$i'),
                ),
                ChoiceBlock() => _ChoiceCard(block: b, index: i, onKeys: onKeys),
                InputBlock() => const SizedBox.shrink(),
              },
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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.block, required this.index, required this.onKeys});
  final ChoiceBlock block;
  final int index;
  final ValueChanged<List<String>> onKeys;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final l = context.l10n;
    return Container(
      key: Key('choice-block-$index'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(MoshRadii.card),
        border: Border.all(color: c.accent, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.agentViewQuestion,
            style: TextStyle(color: c.muted, fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(block.question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final (i, o) in block.options.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ChoiceButton(
                key: Key('choice-$i'),
                option: o,
                onPressed: () => onKeys(o.keys),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({super.key, required this.option, required this.onPressed});
  final ChoiceOption option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final label = Text(option.label, maxLines: 2, overflow: TextOverflow.ellipsis);
    final icon = Icon(switch (option.kind) {
      ChoiceKind.allow => Icons.check,
      ChoiceKind.allowAlways => Icons.done_all,
      ChoiceKind.deny => Icons.close,
      ChoiceKind.other => option.selected ? Icons.radio_button_checked : Icons.chevron_right,
    });
    const size = Size.fromHeight(56);
    return switch (option.kind) {
      ChoiceKind.allow => FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: size,
          backgroundColor: Colors.green.shade800,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      ChoiceKind.allowAlways => FilledButton.icon(
        style: FilledButton.styleFrom(
          minimumSize: size,
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
        ),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      ChoiceKind.deny => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          foregroundColor: c.danger,
          side: BorderSide(color: c.danger, width: 2),
        ),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
      ChoiceKind.other => FilledButton.tonalIcon(
        style: FilledButton.styleFrom(minimumSize: size),
        onPressed: onPressed,
        icon: icon,
        label: label,
      ),
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
