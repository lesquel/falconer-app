import 'package:flutter/material.dart';

import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/appearance.dart';

/// Accent color, app theme and terminal scheme, with a live preview.
class ColorsView extends StatelessWidget {
  const ColorsView({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onBack,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback onBack;

  static const _themeLabels = {
    ThemePreference.system: 'System',
    ThemePreference.light: 'Light',
    ThemePreference.dark: 'Dark',
  };

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final c = MoshColors.of(context);
    return ThumbPage(
      onBack: onBack,
      caption: 'Settings › Colors',
      title: const Text('Colors'),
      children: [
        _Preview(accent: c.accent, onAccent: c.onAccent, scheme: s.terminalScheme),
        const SectionLabel('Accent'),
        _Grid(
          children: [
            for (final a in AccentColor.values)
              _Swatch(
                key: Key('accent_${a.name}'),
                accent: a,
                isDark: c.isDark,
                selected: a == s.accent,
                onTap: () => onChanged(s.copyWith(accent: a)),
              ),
          ],
        ),
        const SectionLabel('App'),
        _Grid(
          children: [
            for (final p in ThemePreference.values)
              _Choice(
                key: Key('theme_${p.name}'),
                label: _themeLabels[p]!,
                selected: p == s.themePreference,
                onTap: () => onChanged(s.copyWith(themePreference: p)),
              ),
          ],
        ),
        const SectionLabel('Terminal'),
        _Grid(
          children: [
            for (final t in TerminalScheme.values)
              _SchemeChoice(
                key: Key('scheme_${t.name}'),
                scheme: t,
                selected: t == s.terminalScheme,
                onTap: () => onChanged(s.copyWith(terminalScheme: t)),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 0),
          child: Text(
            'Every accent is checked for 4.5:1 contrast in the light and dark themes.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c.muted),
          ),
        ),
      ],
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: children[i]),
      ],
    ],
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.accent, required this.onAccent, required this.scheme});
  final Color accent;
  final Color onAccent;
  final TerminalScheme scheme;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final p = scheme.palette;
    final mono = TextStyle(fontFamily: 'monospace', fontSize: 13, color: Color(p.foreground));
    return MoshTile(
      radius: MoshRadii.hero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Preview', style: TextStyle(fontSize: 12, color: c.muted)),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Container(
              height: 76,
              padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(MoshRadii.tile),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'Approve',
                      style: TextStyle(color: onAccent, fontWeight: FontWeight.w800, fontSize: 18),
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: onAccent,
                    child: Icon(Icons.check, color: accent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(p.background),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text.rich(
              TextSpan(
                style: mono,
                children: [
                  TextSpan(
                    text: '❯ ',
                    style: TextStyle(color: Color(p.ansi[4])),
                  ),
                  const TextSpan(text: 'npm test '),
                  TextSpan(
                    text: '42 passed',
                    style: TextStyle(color: Color(p.ansi[2])),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selection mark: shape, not only color, tells which choice is active.
class _Check extends StatelessWidget {
  const _Check({required this.color, required this.background});
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(color: background, shape: BoxShape.circle),
    child: Icon(Icons.check, size: 16, color: color),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.accent,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final AccentColor accent;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final fill = Color(accent.forDark(isDark));
    final on = Color(accent.onAccent(isDark));
    return Semantics(
      label: '${accent.label} accent',
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoshRadii.key),
          side: selected
              ? BorderSide(color: c.foreground, width: 3)
              : BorderSide(color: c.surfaceHigh),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 52,
            child: Center(
              child: selected ? _Check(color: fill, background: on) : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    return MoshTile(
      tone: selected ? TileTone.inverse : TileTone.card,
      radius: 20,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      selected: selected,
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            Icon(Icons.check, size: 18, color: c.onInverse),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _SchemeChoice extends StatelessWidget {
  const _SchemeChoice({
    super.key,
    required this.scheme,
    required this.selected,
    required this.onTap,
  });

  final TerminalScheme scheme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = MoshColors.of(context);
    final p = scheme.palette;
    final fg = Color(p.foreground);
    final short = scheme == TerminalScheme.highContrast ? 'High' : scheme.label;
    return Semantics(
      label: '${scheme.label} terminal',
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      child: Material(
        color: Color(p.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: selected
              ? BorderSide(color: c.foreground, width: 3)
              : BorderSide(color: c.surfaceHigh),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (selected) ...[Icon(Icons.check, size: 16, color: fg), const SizedBox(width: 2)],
                Flexible(
                  child: Text(
                    short,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
