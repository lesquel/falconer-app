import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';

import '../../../settings/domain/entities/appearance.dart';

/// xterm colors for a [TerminalScheme] chosen on the Colors screen.
TerminalTheme terminalThemeFor(TerminalScheme scheme) {
  final p = scheme.palette;
  Color a(int i) => Color(p.ansi[i]);
  return TerminalTheme(
    cursor: Color(p.cursor),
    selection: Color(p.selection),
    foreground: Color(p.foreground),
    background: Color(p.background),
    black: a(0),
    red: a(1),
    green: a(2),
    yellow: a(3),
    blue: a(4),
    magenta: a(5),
    cyan: a(6),
    white: a(7),
    brightBlack: a(8),
    brightRed: a(9),
    brightGreen: a(10),
    brightYellow: a(11),
    brightBlue: a(12),
    brightMagenta: a(13),
    brightCyan: a(14),
    brightWhite: a(15),
    searchHitBackground: a(11),
    searchHitBackgroundCurrent: a(10),
    searchHitForeground: a(0),
  );
}
