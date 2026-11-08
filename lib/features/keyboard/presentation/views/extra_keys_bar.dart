import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/key_cap.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/extra_key.dart';
import '../../domain/entities/modifier_state.dart';

/// UI-G keys bar: a grid of big keys (the first [gridKeys] base keys, a
/// "more keys" toggle and the [pinned] controls). When expanded, two
/// scrollable rows add the rest of the base keys, [trailing] and the preset.
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
  });

  final List<ExtraKey> base;
  final List<ExtraKey> preset;
  final ModifierState modifiers;
  final ValueChanged<String> onKey;
  final ValueChanged<Modifier> onModifier;
  final ValueChanged<Modifier> onModifierLock;

  /// Extra controls at the end of the expanded base row (zoom).
  final List<Widget> trailing;

  /// Controls that never go away (chat, keyboard), in the grid.
  final List<Widget> pinned;

  /// Shows the scrollable rows below the grid.
  final bool expanded;

  /// When null there is no toggle and the rows follow [expanded].
  final VoidCallback? onToggleExpanded;
  final int gridKeys;

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
    final rest = base.skip(gridKeys).toList();
    final cells = <Widget>[
      for (final k in head) _cap(k, grid: true),
      if (onToggleExpanded != null)
        KeyGridButton(
          key: const Key('more_keys'),
          tooltip: expanded ? 'Fewer keys' : 'More keys',
          selected: expanded,
          icon: expanded ? Icons.unfold_less : Icons.unfold_more,
          onPressed: onToggleExpanded!,
        ),
      ...pinned,
    ];
    return Material(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (expanded) ...[
                _row(rest, extra: trailing),
                if (preset.isNotEmpty) _row(preset),
                const SizedBox(height: 4),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: SizedBox(height: 52, child: cells[i])),
                    ],
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
