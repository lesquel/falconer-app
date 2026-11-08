import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/atoms/key_cap.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/extra_key.dart';
import '../../domain/entities/modifier_state.dart';

/// UI-G keys bar: a grid of big keys (the first [gridKeys] base keys, a
/// "more keys" toggle and the [pinned] controls). When expanded, two
/// scrollable rows add the rest of the base keys, [trailing] and the preset.
const _arrows = {'\x1b[A', '\x1b[B', '\x1b[C', '\x1b[D'};

class ExtraKeysBar extends StatelessWidget {
  const ExtraKeysBar({
    super.key,
    required this.base,
    required this.preset,
    required this.modifiers,
    required this.onKey,
    required this.onModifier,
    required this.onModifierLock,
    this.trailing = const [],
    this.pinned = const [],
    this.expanded = true,
    this.onToggleExpanded,
    this.gridKeys = 3,
    this.shortcuts = const [],
    this.onShortcutLongPress,
    this.shortcutExtras = const [],
  });

  final List<ExtraKey> base;
  final List<ExtraKey> preset;
  final ModifierState modifiers;
  final ValueChanged<String> onKey;
  final ValueChanged<Modifier> onModifier;
  final ValueChanged<Modifier> onModifierLock;

  /// Extra controls at the end of the expanded base row (text size).
  final List<Widget> trailing;

  /// Controls that never go away (chat, keyboard), in the grid.
  final List<Widget> pinned;

  /// Shows the scrollable rows below the grid.
  final bool expanded;

  /// When null there is no toggle and the rows follow [expanded].
  final VoidCallback? onToggleExpanded;
  final int gridKeys;

  /// The user's saved shortcut keys, first row of the expanded bar.
  final List<ExtraKey> shortcuts;

  /// Long press on saved shortcut `i` (edit or delete it).
  final ValueChanged<int>? onShortcutLongPress;

  /// Controls after the saved shortcuts (paste, add).
  final List<Widget> shortcutExtras;

  bool _active(Modifier m) => m == Modifier.ctrl ? modifiers.ctrl : modifiers.alt;
  bool _locked(Modifier m) => m == Modifier.ctrl ? modifiers.ctrlLocked : modifiers.altLocked;

  Widget _cap(ExtraKey k, {bool grid = false}) => k.modifier != null
      ? KeyCap(
          label: k.label,
          active: _active(k.modifier!),
          locked: _locked(k.modifier!),
          height: grid ? 52 : 44,
          expand: grid,
          onTap: () => onModifier(k.modifier!),
          onLongPress: () => onModifierLock(k.modifier!),
        )
      : KeyCap(
          label: k.label,
          height: grid ? 52 : 44,
          expand: grid,
          onTap: () => onKey(k.sequence!),
        );

  Widget _row(List<ExtraKey> keys, {List<Widget> extra = const []}) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    child: Row(children: [for (final k in keys) _cap(k), ...extra]),
  );

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final head = base.take(gridKeys).toList();
    // Arrows live on the always-visible cross, not in the scrolling rows.
    final rest = base.skip(gridKeys).where((k) => !_arrows.contains(k.sequence)).toList();
    final cells = <Widget>[
      for (final k in head) _cap(k, grid: true),
      if (onToggleExpanded != null)
        KeyGridButton(
          key: const Key('more_keys'),
          tooltip: expanded ? context.l10n.fewerKeys : context.l10n.moreKeys,
          selected: expanded,
          icon: expanded ? Icons.unfold_less : Icons.unfold_more,
          onPressed: onToggleExpanded!,
        ),
      ...pinned,
    ];
    // Phones keep one compact row of keys; the arrows and extra rows show
    // with "more keys". Tablets get a 2x3 grid with the cross beside it.
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final perRow = wide ? 3 : cells.length;
    return Material(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expanded)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (shortcuts.isNotEmpty || shortcutExtras.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 7),
                              child: Row(
                                children: [
                                  for (var i = 0; i < shortcuts.length; i++)
                                    KeyCap(
                                      key: Key('shortcut_$i'),
                                      label: shortcuts[i].label,
                                      onTap: () => onKey(shortcuts[i].sequence!),
                                      onLongPress: onShortcutLongPress == null
                                          ? null
                                          : () => onShortcutLongPress!(i),
                                    ),
                                  ...shortcutExtras,
                                ],
                              ),
                            ),
                          _row(rest, extra: trailing),
                          if (preset.isNotEmpty) _row(preset),
                        ],
                      ),
                    ),
                    // On a phone the arrows live with the extra rows.
                    if (!wide) ...[ArrowCross(onKey: onKey), const SizedBox(width: 10)],
                  ],
                ),
              if (expanded) const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (var r = 0; r * perRow < cells.length; r++) ...[
                            if (r > 0) const SizedBox(height: 8),
                            Row(
                              children: [
                                for (
                                  var i = r * perRow;
                                  i < cells.length && i < (r + 1) * perRow;
                                  i++
                                ) ...[
                                  if (i > r * perRow) const SizedBox(width: 8),
                                  Expanded(child: SizedBox(height: 52, child: cells[i])),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // On a tablet the cross is always beside the grid.
                    if (wide) ...[const SizedBox(width: 10), ArrowCross(onKey: onKey)],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon cell of the keys grid. Selected cells are inverted and use a
/// different icon, so the state does not rely on color.
class KeyGridButton extends StatelessWidget {
  const KeyGridButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.selectedIcon,
  });

  final String tooltip;
  final IconData icon;
  final IconData? selectedIcon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return IconButton(
      tooltip: tooltip,
      isSelected: selected,
      onPressed: onPressed,
      icon: Icon(icon),
      selectedIcon: Icon(selectedIcon ?? icon),
      style: IconButton.styleFrom(
        backgroundColor: selected ? c.inverse : c.surface,
        foregroundColor: selected ? c.onInverse : c.foreground,
        disabledForegroundColor: c.muted,
        minimumSize: const Size(44, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(MoshRadii.key - 4)),
      ),
    );
  }
}

/// Always-visible arrow keys in a cross. Holding an arrow repeats it.
class ArrowCross extends StatelessWidget {
  const ArrowCross({super.key, required this.onKey, this.size = 36});
  final ValueChanged<String> onKey;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget key(String seq, IconData icon, String label) => SizedBox.square(
      dimension: size,
      child: _RepeatKey(sequence: seq, icon: icon, label: label, onKey: onKey),
    );
    final gap = SizedBox.square(dimension: size);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [gap, key('\x1b[A', Icons.keyboard_arrow_up, l.arrowUp), gap],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            key('\x1b[D', Icons.keyboard_arrow_left, l.arrowLeft),
            // Enter in the middle: submits the prompt in any agent.
            key('\r', Icons.keyboard_return, l.enterKey),
            key('\x1b[C', Icons.keyboard_arrow_right, l.arrowRight),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [gap, key('\x1b[B', Icons.keyboard_arrow_down, l.arrowDown), gap],
        ),
      ],
    );
  }
}

class _RepeatKey extends StatefulWidget {
  const _RepeatKey({
    required this.sequence,
    required this.icon,
    required this.label,
    required this.onKey,
  });
  final String sequence;
  final IconData icon;
  final String label;
  final ValueChanged<String> onKey;

  @override
  State<_RepeatKey> createState() => _RepeatKeyState();
}

class _RepeatKeyState extends State<_RepeatKey> {
  Timer? _repeat;

  void _start() {
    _stop();
    _repeat = Timer.periodic(
      const Duration(milliseconds: 80),
      (_) => widget.onKey(widget.sequence),
    );
  }

  void _stop() {
    _repeat?.cancel();
    _repeat = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return Semantics(
      label: widget.label,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        onLongPressStart: (_) => _start(),
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: Material(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget.onKey(widget.sequence),
            child: Center(child: Icon(widget.icon, size: 22, color: c.foreground)),
          ),
        ),
      ),
    );
  }
}
