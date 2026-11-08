import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/l10n.dart';
import '../shared/ui/tokens/mosh_colors.dart';

/// Bottom dock of big rounded tiles (UI-G). The selected tile is inverted and
/// also shows its label, so the state is not shown by color alone.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});
  final StatefulNavigationShell shell;

  static const destinations = [Icons.computer, Icons.inbox_outlined, Icons.key, Icons.tune];

  static String label(AppLocalizations l, int index) =>
      [l.navHosts, l.navInbox, l.navKeys, l.navSettings][index];

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: HomeDock(
      selectedIndex: shell.currentIndex,
      onSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
    ),
  );
}

class HomeDock extends StatelessWidget {
  const HomeDock({super.key, required this.selectedIndex, required this.onSelected});
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return ColoredBox(
      color: c.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              for (var i = 0; i < HomeShell.destinations.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _DockTile(index: i, selected: i == selectedIndex, onTap: onSelected),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DockTile extends StatelessWidget {
  const _DockTile({required this.index, required this.selected, required this.onTap});
  final int index;
  final bool selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final icon = HomeShell.destinations[index];
    final label = HomeShell.label(context.l10n, index);
    final fg = selected ? c.onInverse : c.foreground;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? c.inverse : c.surface,
          borderRadius: BorderRadius.circular(MoshRadii.tile),
          child: InkWell(
            borderRadius: BorderRadius.circular(MoshRadii.tile),
            onTap: () => onTap(index),
            child: SizedBox(
              height: 64,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: fg),
                  if (selected)
                    Text(
                      label,
                      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
