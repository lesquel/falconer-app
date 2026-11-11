import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../keyboard/domain/entities/key_presets.dart';
import '../../../voice/domain/entities/voice_selection.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/appearance.dart';
import 'notification_hours_tile.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onAppLockChanged,
    this.onOpenColors,
    this.onOpenVoice,
    this.webPush,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  /// The lock setting is saved by the container after user verification.
  final ValueChanged<bool> onAppLockChanged;
  final VoidCallback? onOpenColors;
  final VoidCallback? onOpenVoice;

  /// Web notifications section (iOS / browser); first on Apple platforms.
  final Widget? webPush;

  static String themeLabel(AppLocalizations l, ThemePreference p) => switch (p) {
    ThemePreference.system => l.themeSummarySystem,
    ThemePreference.light => l.themeSummaryLight,
    ThemePreference.dark => l.themeSummaryDark,
  };

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final c = MoshColors.of(context);
    final l = context.l10n;
    Widget card(List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MoshTile(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
    return ThumbPage(
      title: Text(l.settingsTitle),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: MoshTile(
            key: const Key('open_colors'),
            radius: MoshRadii.hero,
            onTap: onOpenColors,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                  child: Icon(Icons.palette_outlined, color: c.onAccent),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.colors,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        l.colorsSummary(
                          l.accentName(s.accent),
                          themeLabel(l, s.themePreference),
                          l.schemeName(s.terminalScheme),
                        ),
                        style: TextStyle(color: c.muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
        // Light / dark and language at a glance; Colors keeps the accent and terminal.
        card([
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appTheme, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemePreference>(
                    key: const Key('theme_switch'),
                    segments: [
                      ButtonSegment(
                        value: ThemePreference.system,
                        icon: const Icon(Icons.brightness_auto_outlined),
                        label: Text(l.themeName(ThemePreference.system)),
                      ),
                      ButtonSegment(
                        value: ThemePreference.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(l.themeName(ThemePreference.light)),
                      ),
                      ButtonSegment(
                        value: ThemePreference.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(l.themeName(ThemePreference.dark)),
                      ),
                    ],
                    selected: {s.themePreference},
                    showSelectedIcon: false,
                    onSelectionChanged: (v) => onChanged(s.copyWith(themePreference: v.first)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  key: const Key('language'),
                  children: [
                    const Icon(Icons.translate, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(l.language, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    DropdownButton<AppLanguage>(
                      value: s.language,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(MoshRadii.key),
                      items: [
                        for (final lang in AppLanguage.values)
                          DropdownMenuItem(
                            key: Key('language_${lang.name}'),
                            value: lang,
                            child: Text(l.languageName(lang)),
                          ),
                      ],
                      onChanged: (v) => v == null ? null : onChanged(s.copyWith(language: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ]),
        ?webPush,
        card([
          SwitchListTile(
            key: const Key('previews'),
            title: Text(l.notificationPreviews),
            subtitle: Text(l.notificationPreviewsBody),
            value: s.notificationPreviews,
            onChanged: (v) => onChanged(s.copyWith(notificationPreviews: v)),
          ),
          NotificationHoursTile(
            hours: s.notificationHours,
            onChanged: (c) => onChanged(
              s.withNotificationHours(switch (c) {
                SetHours(:final hours) => hours,
                InheritHours() => null,
              }),
            ),
          ),
          SwitchListTile(
            key: const Key('keep_connected'),
            title: Text(l.keepConnected),
            subtitle: Text(l.keepConnectedBody),
            value: s.keepConnected,
            onChanged: (v) => onChanged(s.copyWith(keepConnected: v)),
          ),
          SwitchListTile(
            key: const Key('app_lock'),
            title: Text(l.lockApp),
            subtitle: Text(l.lockAppBody),
            value: s.appLock,
            onChanged: onAppLockChanged,
          ),
        ]),
        card([
          ListTile(
            title: Text(l.terminalFontSize(s.fontSize.toStringAsFixed(0))),
            subtitle: Slider(
              min: 8,
              max: 32,
              divisions: 24,
              value: s.fontSize.clamp(8, 32),
              label: s.fontSize.toStringAsFixed(0),
              onChanged: (v) => onChanged(s.copyWith(fontSize: v)),
            ),
          ),
          ListTile(
            title: Text(l.shortcutRow),
            trailing: DropdownButton<PresetName>(
              value: s.keyPreset,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(MoshRadii.key),
              items: [
                DropdownMenuItem(value: PresetName.none, child: Text(l.presetNone)),
                const DropdownMenuItem(value: PresetName.tmux, child: Text('tmux')),
                const DropdownMenuItem(value: PresetName.herdr, child: Text('Herdr')),
              ],
              onChanged: (v) => v == null ? null : onChanged(s.copyWith(keyPreset: v)),
            ),
          ),
          ListTile(
            title: Text(l.herdrPrefix),
            subtitle: Text('Ctrl+${s.herdrPrefix.toUpperCase()}'),
            trailing: DropdownButton<String>(
              value: s.herdrPrefix,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(MoshRadii.key),
              items: [
                for (final ch in 'abs'.split(''))
                  DropdownMenuItem(value: ch, child: Text('Ctrl+${ch.toUpperCase()}')),
              ],
              onChanged: (v) => v == null ? null : onChanged(s.copyWith(herdrPrefix: v)),
            ),
          ),
        ]),
        card([
          ListTile(
            key: const Key('open_voice'),
            leading: const Icon(Icons.mic_none),
            title: Text(l.voiceTitle),
            subtitle: Text(selectedVoiceModel(s)?.name ?? l.voiceSummaryNone),
            trailing: const Icon(Icons.chevron_right),
            onTap: onOpenVoice,
          ),
        ]),
        card([
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l.privacy),
            subtitle: Text(l.privacyBody),
          ),
        ]),
      ],
    );
  }
}
