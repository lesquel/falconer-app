import 'package:flutter/material.dart';

import '../../../../shared/ui/molecules/mosh_tile.dart';
import '../../../../shared/ui/organisms/thumb_page.dart';
import '../../../../shared/ui/tokens/mosh_colors.dart';
import '../../../keyboard/domain/entities/key_presets.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/appearance.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.settings,
    required this.onChanged,
    this.onOpenColors,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;
  final VoidCallback? onOpenColors;

  static String themeLabel(ThemePreference p) => switch (p) {
    ThemePreference.system => 'system theme',
    ThemePreference.light => 'light theme',
    ThemePreference.dark => 'dark theme',
  };

  @override
  Widget build(BuildContext context) {
    final s = settings;
    final c = MoshColors.of(context);
    Widget card(List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MoshTile(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(children: children),
      ),
    );
    return ThumbPage(
      title: const Text('Settings'),
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
                      const Text(
                        'Colors',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${s.accent.label} accent · ${themeLabel(s.themePreference)} · '
                        '${s.terminalScheme.label} terminal',
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
        card([
          SwitchListTile(
            key: const Key('previews'),
            title: const Text('Notification previews'),
            subtitle: const Text(
              'Off: notifications only say "<host>: <agent> needs you". '
              'On: they show the request text, hidden on the lock screen.',
            ),
            value: s.notificationPreviews,
            onChanged: (v) => onChanged(s.copyWith(notificationPreviews: v)),
          ),
          SwitchListTile(
            key: const Key('keep_connected'),
            title: const Text('Keep sessions connected'),
            subtitle: const Text(
              'Terminals stay open and keep reconnecting after you leave them, until you '
              'disconnect or close the app.',
            ),
            value: s.keepConnected,
            onChanged: (v) => onChanged(s.copyWith(keepConnected: v)),
          ),
          SwitchListTile(
            key: const Key('app_lock'),
            title: const Text('Lock OpenMosh'),
            subtitle: const Text(
              'Ask for your fingerprint, face or screen lock when OpenMosh opens and after '
              'a minute in the background.',
            ),
            value: s.appLock,
            onChanged: (v) => onChanged(s.copyWith(appLock: v)),
          ),
        ]),
        card([
          ListTile(
            title: Text('Terminal font size · ${s.fontSize.toStringAsFixed(0)}'),
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
            title: const Text('Shortcut row'),
            trailing: DropdownButton<PresetName>(
              value: s.keyPreset,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(MoshRadii.key),
              items: const [
                DropdownMenuItem(value: PresetName.none, child: Text('None')),
                DropdownMenuItem(value: PresetName.tmux, child: Text('tmux')),
                DropdownMenuItem(value: PresetName.herdr, child: Text('Herdr')),
              ],
              onChanged: (v) => v == null ? null : onChanged(s.copyWith(keyPreset: v)),
            ),
          ),
          ListTile(
            title: const Text('Herdr prefix'),
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
        card(const [
          ListTile(
            leading: Icon(Icons.shield_outlined),
            title: Text('Privacy'),
            subtitle: Text(
              'No accounts, analytics or crash reporting. The app only talks to your hosts over '
              'Tailscale and to your UnifiedPush server, which sees ciphertext only.',
            ),
          ),
        ]),
      ],
    );
  }
}
