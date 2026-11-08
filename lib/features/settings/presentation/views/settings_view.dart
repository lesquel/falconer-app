import 'package:flutter/material.dart';

import '../../../keyboard/domain/entities/key_presets.dart';
import '../../domain/entities/app_settings.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.settings, required this.onChanged});
  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = settings;
    return ListView(
      children: [
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
          title: const Text('Dark theme'),
          value: s.darkTheme,
          onChanged: (v) => onChanged(s.copyWith(darkTheme: v)),
        ),
        ListTile(
          title: const Text('Terminal font size'),
          subtitle: Slider(
            min: 8,
            max: 24,
            divisions: 16,
            value: s.fontSize.clamp(8, 24),
            label: s.fontSize.toStringAsFixed(0),
            onChanged: (v) => onChanged(s.copyWith(fontSize: v)),
          ),
        ),
        ListTile(
          title: const Text('Shortcut row'),
          trailing: DropdownButton<PresetName>(
            value: s.keyPreset,
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
            items: [
              for (final c in 'abs'.split(''))
                DropdownMenuItem(value: c, child: Text('Ctrl+${c.toUpperCase()}')),
            ],
            onChanged: (v) => v == null ? null : onChanged(s.copyWith(herdrPrefix: v)),
          ),
        ),
        const Divider(),
        const ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('Privacy'),
          subtitle: Text(
            'No accounts, analytics or crash reporting. The app only talks to your hosts over '
            'Tailscale and to your UnifiedPush server, which sees ciphertext only.',
          ),
        ),
      ],
    );
  }
}
