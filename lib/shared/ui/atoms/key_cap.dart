import 'package:flutter/material.dart';

import '../tokens/mosh_colors.dart';

/// One key on the extra-keys bar. An active modifier is inverted and gets a
/// dot (a lock when locked), so its state is not shown by color alone.
class KeyCap extends StatelessWidget {
  const KeyCap({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
    this.locked = false,
    this.onLongPress,
    this.height = 44,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool active;
  final bool locked;
  final double height;

  /// Fill the width given by the parent (grid cell) instead of hugging the label.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final fg = active ? c.onInverse : c.foreground;
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      style: TextStyle(fontFamily: 'monospace', color: fg, fontWeight: FontWeight.w700),
    );
    return Padding(
      padding: expand ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Semantics(
        label: label,
        button: true,
        toggled: onLongPress != null ? active : null,
        excludeSemantics: true,
        child: Material(
          color: active ? c.inverse : c.surface,
          borderRadius: BorderRadius.circular(MoshRadii.key - 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(MoshRadii.key - 4),
            onTap: onTap,
            onLongPress: onLongPress,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: 44, minHeight: height),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: expand ? 4 : 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      text,
                      if (active)
                        locked
                            ? Icon(Icons.lock, size: 10, color: fg)
                            : Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                              ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
