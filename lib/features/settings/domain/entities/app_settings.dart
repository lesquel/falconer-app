import '../../../keyboard/domain/entities/key_presets.dart';
import 'appearance.dart';

final class AppSettings {
  const AppSettings({
    this.notificationPreviews = false,
    this.themePreference = ThemePreference.system,
    this.accent = AccentColor.blue,
    this.terminalScheme = TerminalScheme.black,
    this.fontSize = 14,
    this.keyPreset = PresetName.tmux,
    this.herdrPrefix = 'b',
    this.keepConnected = true,
  });

  /// Off by default (SEC-2): the lock screen shows only `<alias>: <agent> needs you`.
  final bool notificationPreviews;

  /// App theme: follow the system, or force light or dark.
  final ThemePreference themePreference;

  /// The one accent color used for primary actions and highlights.
  final AccentColor accent;

  /// Colors of the terminal, independent of the app theme.
  final TerminalScheme terminalScheme;

  final double fontSize;
  final PresetName keyPreset;

  /// Letter used with Ctrl as the Herdr prefix (`b` → Ctrl+B).
  final String herdrPrefix;

  /// Keep terminal sessions connected (and reconnecting) after leaving the
  /// terminal screen, until the app is closed or the session is disconnected.
  final bool keepConnected;

  String get herdrPrefixSequence {
    final c = herdrPrefix.toLowerCase().codeUnitAt(0);
    return (c >= 0x61 && c <= 0x7a) ? String.fromCharCode(c - 0x60) : '\x02';
  }

  AppSettings copyWith({
    bool? notificationPreviews,
    ThemePreference? themePreference,
    AccentColor? accent,
    TerminalScheme? terminalScheme,
    double? fontSize,
    PresetName? keyPreset,
    String? herdrPrefix,
    bool? keepConnected,
  }) => AppSettings(
    notificationPreviews: notificationPreviews ?? this.notificationPreviews,
    themePreference: themePreference ?? this.themePreference,
    accent: accent ?? this.accent,
    terminalScheme: terminalScheme ?? this.terminalScheme,
    fontSize: (fontSize ?? this.fontSize).clamp(8, 32).toDouble(),
    keyPreset: keyPreset ?? this.keyPreset,
    herdrPrefix: herdrPrefix ?? this.herdrPrefix,
    keepConnected: keepConnected ?? this.keepConnected,
  );
}
