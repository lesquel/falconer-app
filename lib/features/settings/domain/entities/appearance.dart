/// Appearance choices: app theme, accent color and terminal color scheme.
///
/// Colors are stored as ARGB integers so the domain stays free of Flutter.
library;

/// Which app theme to use. `system` follows the phone's dark-mode setting.
enum ThemePreference { system, light, dark }

/// Accent colors offered on the Colors screen.
///
/// Each accent has one shade for the dark theme and one for the light theme,
/// chosen so the accent passes WCAG 2.2 AA (4.5:1) as text on every surface of
/// its theme and against the text drawn on top of it ([onDark] / [onLight]).
enum AccentColor {
  blue('Blue', 0xFF6B93FF, 0xFF1F4FD8),
  green('Green', 0xFF4ADE9E, 0xFF0B7046),
  violet('Violet', 0xFFB69CFF, 0xFF6338D1),
  amber('Amber', 0xFFFFC24D, 0xFF835600),
  coral('Coral', 0xFFFF8F7A, 0xFFB0361F),
  white('White', 0xFFFAFAFA, 0xFF0A0A0A);

  const AccentColor(this.label, this.dark, this.light);

  final String label;

  /// Accent on the dark theme; text on it is black.
  final int dark;

  /// Accent on the light theme; text on it is white.
  final int light;

  int forDark(bool isDark) => isDark ? dark : light;

  /// Text and icon color drawn on top of the accent.
  int onAccent(bool isDark) => isDark ? 0xFF000000 : 0xFFFFFFFF;
}

/// Colors of one terminal scheme (xterm's 16 ANSI colors plus UI colors).
final class TerminalPalette {
  const TerminalPalette({
    required this.background,
    required this.foreground,
    required this.cursor,
    required this.selection,
    required this.ansi,
  });

  final int background;
  final int foreground;
  final int cursor;
  final int selection;

  /// black, red, green, yellow, blue, magenta, cyan, white, then the bright set.
  final List<int> ansi;
}

/// Terminal color schemes, independent of the app theme.
enum TerminalScheme {
  black(
    'Black',
    TerminalPalette(
      background: 0xFF000000,
      foreground: 0xFFE5E5E5,
      cursor: 0xFFFAFAFA,
      selection: 0x66A3A3A3,
      ansi: [
        0xFF000000, 0xFFFF6B6B, 0xFF4ADE9E, 0xFFFFC24D, //
        0xFF6B93FF, 0xFFB69CFF, 0xFF5FD7E0, 0xFFE5E5E5,
        0xFF8F8F8F, 0xFFFF8F8F, 0xFF7AF0BC, 0xFFFFD580,
        0xFF94B2FF, 0xFFCDB9FF, 0xFF8CE8EF, 0xFFFFFFFF,
      ],
    ),
  ),
  paper(
    'Paper',
    TerminalPalette(
      background: 0xFFFAFAFA,
      foreground: 0xFF1A1A1A,
      cursor: 0xFF0A0A0A,
      selection: 0x55525252,
      ansi: [
        0xFF1A1A1A, 0xFFB3261E, 0xFF0B7046, 0xFF835600, //
        0xFF1F4FD8, 0xFF6338D1, 0xFF00687A, 0xFF525252,
        0xFF404040, 0xFFB0361F, 0xFF0B6A43, 0xFF7A5000,
        0xFF1A44BD, 0xFF5A30C0, 0xFF005E6E, 0xFF0A0A0A,
      ],
    ),
  ),
  sepia(
    'Sepia',
    TerminalPalette(
      background: 0xFF2A2620,
      foreground: 0xFFE8DCC4,
      cursor: 0xFFE8DCC4,
      selection: 0x66A89A80,
      ansi: [
        0xFF2A2620, 0xFFE6886F, 0xFFA8C77F, 0xFFE8C170, //
        0xFF8FB0D9, 0xFFC9A3D1, 0xFF8CC7BA, 0xFFE8DCC4,
        0xFFA89A80, 0xFFF0A08A, 0xFFBFD89A, 0xFFF2D290,
        0xFFAAC4E6, 0xFFDABBE0, 0xFFA6DACE, 0xFFFFF6E0,
      ],
    ),
  ),
  highContrast(
    'High contrast',
    TerminalPalette(
      background: 0xFF000000,
      foreground: 0xFFFFFFFF,
      cursor: 0xFFFFFF00,
      selection: 0x88FFFF00,
      ansi: [
        0xFF000000, 0xFFFF5555, 0xFF55FF55, 0xFFFFFF00, //
        0xFF7FA6FF, 0xFFFF77FF, 0xFF55FFFF, 0xFFFFFFFF,
        0xFFBDBDBD, 0xFFFF8080, 0xFF80FF80, 0xFFFFFF80,
        0xFFA8C4FF, 0xFFFFA0FF, 0xFF80FFFF, 0xFFFFFFFF,
      ],
    ),
  );

  const TerminalScheme(this.label, this.palette);

  final String label;
  final TerminalPalette palette;
}
