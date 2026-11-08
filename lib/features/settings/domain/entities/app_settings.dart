import '../../../keyboard/domain/entities/key_presets.dart';

final class AppSettings {
  const AppSettings({
    this.notificationPreviews = false,
    this.darkTheme = true,
    this.fontSize = 14,
    this.keyPreset = PresetName.tmux,
    this.herdrPrefix = 'b',
  });

  /// Off by default (SEC-2): the lock screen shows only `<alias>: <agent> needs you`.
  final bool notificationPreviews;
  final bool darkTheme;
  final double fontSize;
  final PresetName keyPreset;

  /// Letter used with Ctrl as the Herdr prefix (`b` → Ctrl+B).
  final String herdrPrefix;

  String get herdrPrefixSequence {
    final c = herdrPrefix.toLowerCase().codeUnitAt(0);
    return (c >= 0x61 && c <= 0x7a) ? String.fromCharCode(c - 0x60) : '\x02';
  }

  AppSettings copyWith({bool? notificationPreviews, bool? darkTheme, double? fontSize, PresetName? keyPreset, String? herdrPrefix}) =>
      AppSettings(
        notificationPreviews: notificationPreviews ?? this.notificationPreviews,
        darkTheme: darkTheme ?? this.darkTheme,
        fontSize: (fontSize ?? this.fontSize).clamp(8, 32).toDouble(),
        keyPreset: keyPreset ?? this.keyPreset,
        herdrPrefix: herdrPrefix ?? this.herdrPrefix,
      );
}
