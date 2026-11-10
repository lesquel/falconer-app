import '../../../keyboard/domain/entities/key_presets.dart';
import '../../../keyboard/domain/entities/extra_key.dart';
import '../../../voice/domain/entities/voice_model.dart';
import 'appearance.dart';
import 'notification_hours.dart';

/// App language. `system` follows the phone's language (English fallback).
enum AppLanguage { system, en, es }

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
    this.appLock = false,
    this.language = AppLanguage.system,
    this.customKeys = defaultCustomKeys,
    this.notificationHours,
    this.hostNotificationHours = const {},
    this.voiceModelId,
    this.voiceLanguage = '',
    this.customVoiceModels = const [],
  });

  /// Saved shortcut keys shown in their own row of the keys bar.
  static const defaultCustomKeys = <ExtraKey>[
    ExtraKey.send('Ctrl+C', '\x03'),
    ExtraKey.send('Ctrl+V', '\x16'),
    ExtraKey.send('Ctrl+D', '\x04'),
    ExtraKey.send('Ctrl+L', '\x0c'),
    ExtraKey.send('Ctrl+R', '\x12'),
  ];

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

  /// "Lock OpenMosh": ask for user verification on a cold start and after
  /// more than 60 s in the background. Off by default.
  final bool appLock;

  final AppLanguage language;

  /// User shortcuts (label + bytes), in the order they were added.
  final List<ExtraKey> customKeys;

  /// When notifications may sound, for every host; null means always.
  final NotificationHours? notificationHours;

  /// Per-host windows (by host id) that replace [notificationHours].
  final Map<String, NotificationHours> hostNotificationHours;

  /// Speech model used by the chat mic; null until the user picks one.
  final String? voiceModelId;

  /// Spoken language code for dictation; empty means "Automatic".
  final String voiceLanguage;

  /// Speech models the user added by URL, in the order they were added.
  final List<VoiceModel> customVoiceModels;

  /// Whether a push from [hostId] may show a notification at [at].
  bool notificationsAllowed(String hostId, DateTime at) =>
      (hostNotificationHours[hostId] ?? notificationHours)?.allows(at) ?? true;

  /// Copy with the app-wide window set, or cleared with null.
  AppSettings withNotificationHours(NotificationHours? hours) =>
      _copy(notificationHours: () => hours);

  /// Copy with the dictation model set, or cleared with null.
  AppSettings withVoiceModel(String? id) => _copy(voiceModelId: () => id);

  /// Copy with [hostId]'s own window set, or removed with null.
  AppSettings withHostNotificationHours(String hostId, NotificationHours? hours) {
    final map = {...hostNotificationHours}..remove(hostId);
    if (hours != null) map[hostId] = hours;
    return _copy(hostNotificationHours: map);
  }

  String get herdrPrefixSequence {
    final c = herdrPrefix.toLowerCase().codeUnitAt(0);
    return (c >= 0x61 && c <= 0x7a) ? String.fromCharCode(c - 0x60) : '\x02';
  }

  AppSettings _copy({
    NotificationHours? Function()? notificationHours,
    Map<String, NotificationHours>? hostNotificationHours,
    String? Function()? voiceModelId,
  }) => AppSettings(
    notificationPreviews: notificationPreviews,
    themePreference: themePreference,
    accent: accent,
    terminalScheme: terminalScheme,
    fontSize: fontSize,
    keyPreset: keyPreset,
    herdrPrefix: herdrPrefix,
    keepConnected: keepConnected,
    appLock: appLock,
    language: language,
    customKeys: customKeys,
    notificationHours: notificationHours != null ? notificationHours() : this.notificationHours,
    hostNotificationHours: hostNotificationHours ?? this.hostNotificationHours,
    voiceModelId: voiceModelId != null ? voiceModelId() : this.voiceModelId,
    voiceLanguage: voiceLanguage,
    customVoiceModels: customVoiceModels,
  );

  AppSettings copyWith({
    bool? notificationPreviews,
    ThemePreference? themePreference,
    AccentColor? accent,
    TerminalScheme? terminalScheme,
    double? fontSize,
    PresetName? keyPreset,
    String? herdrPrefix,
    bool? keepConnected,
    bool? appLock,
    AppLanguage? language,
    List<ExtraKey>? customKeys,
    String? voiceLanguage,
    List<VoiceModel>? customVoiceModels,
  }) => AppSettings(
    notificationPreviews: notificationPreviews ?? this.notificationPreviews,
    themePreference: themePreference ?? this.themePreference,
    accent: accent ?? this.accent,
    terminalScheme: terminalScheme ?? this.terminalScheme,
    fontSize: (fontSize ?? this.fontSize).clamp(8, 32).toDouble(),
    keyPreset: keyPreset ?? this.keyPreset,
    herdrPrefix: herdrPrefix ?? this.herdrPrefix,
    keepConnected: keepConnected ?? this.keepConnected,
    appLock: appLock ?? this.appLock,
    language: language ?? this.language,
    customKeys: customKeys ?? this.customKeys,
    notificationHours: notificationHours,
    hostNotificationHours: hostNotificationHours,
    voiceModelId: voiceModelId,
    voiceLanguage: voiceLanguage ?? this.voiceLanguage,
    customVoiceModels: customVoiceModels ?? this.customVoiceModels,
  );
}
