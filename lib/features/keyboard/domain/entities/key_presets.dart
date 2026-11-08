/// Extra-keys rows: the always-visible base row and multiplexer presets.
library;

import 'extra_key.dart';

enum PresetName { none, tmux, herdr }

abstract final class KeyPresets {
  static const base = <ExtraKey>[
    ExtraKey.send('Esc', '\x1b'),
    ExtraKey.send('Tab', '\t'),
    ExtraKey.modifier('Ctrl', Modifier.ctrl),
    ExtraKey.modifier('Alt', Modifier.alt),
    ExtraKey.send('←', '\x1b[D'),
    ExtraKey.send('↓', '\x1b[B'),
    ExtraKey.send('↑', '\x1b[A'),
    ExtraKey.send('→', '\x1b[C'),
    ExtraKey.send('|', '|'),
    ExtraKey.send('/', '/'),
    ExtraKey.send('~', '~'),
    ExtraKey.send('-', '-'),
  ];

  static const tmuxPrefix = '\x02'; // C-b
  static const herdrDefaultPrefix = '\x02'; // C-b unless configured

  static List<ExtraKey> forName(PresetName name, {String herdrPrefix = herdrDefaultPrefix}) =>
      switch (name) {
        PresetName.none => const [],
        PresetName.tmux => _prefixed(tmuxPrefix, const {
          'new': 'c',
          'next': 'n',
          'prev': 'p',
          'split│': '%',
          'split─': '"',
          'copy': '[',
          'detach': 'd',
        }),
        PresetName.herdr => _prefixed(herdrPrefix, const {
          'pane→': 'l',
          'pane←': 'h',
          'pane↓': 'j',
          'pane↑': 'k',
          'detach': 'd',
        }),
      };

  /// Herdr and tmux sessions get their own keys; a plain shell uses the
  /// preset chosen in Settings.
  static PresetName forSession(String? kind, PresetName fallback) => switch (kind) {
    'herdr' => PresetName.herdr,
    'tmux' => PresetName.tmux,
    _ => fallback,
  };

  static List<ExtraKey> _prefixed(String prefix, Map<String, String> keys) => [
    for (final e in keys.entries) ExtraKey.send(e.key, '$prefix${e.value}'),
  ];
}
