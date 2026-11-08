import 'package:flutter/material.dart';

import '../../../../shared/ui/atoms/key_cap.dart';
import '../../domain/entities/extra_key.dart';
import '../../domain/entities/modifier_state.dart';

/// Two scrollable rows: the base keys and the multiplexer preset.
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
  });

  final List<ExtraKey> base;
  final List<ExtraKey> preset;
  final ModifierState modifiers;
  final ValueChanged<String> onKey;
  final ValueChanged<Modifier> onModifier;
  final ValueChanged<Modifier> onModifierLock;
  final List<Widget> trailing;

  /// Controls that never scroll away (keyboard toggle, zoom), left of the base row.
  final List<Widget> pinned;

  bool _active(Modifier m) => m == Modifier.ctrl ? modifiers.ctrl : modifiers.alt;

  Widget _row(List<ExtraKey> keys, {List<Widget> extra = const []}) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Row(
      children: [
        for (final k in keys)
          k.modifier != null
              ? KeyCap(
                  label: k.label,
                  active: _active(k.modifier!),
                  onTap: () => onModifier(k.modifier!),
                  onLongPress: () => onModifierLock(k.modifier!),
                )
              : KeyCap(label: k.label, onTap: () => onKey(k.sequence!)),
        ...extra,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainer,
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ...pinned,
              Expanded(child: _row(base, extra: trailing)),
            ],
          ),
          if (preset.isNotEmpty) _row(preset),
        ],
      ),
    ),
  );
}
