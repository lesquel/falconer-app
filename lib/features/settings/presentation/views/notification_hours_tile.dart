import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../domain/entities/notification_hours.dart';

/// What the hours dialog returns. For a host, [inherit] clears its own
/// window so the app-wide one applies.
sealed class HoursChoice {
  const HoursChoice();
}

final class InheritHours extends HoursChoice {
  const InheritHours();
}

final class SetHours extends HoursChoice {
  /// Null means always.
  const SetHours(this.hours);
  final NotificationHours? hours;
}

String _hm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String hoursLabel(AppLocalizations l, NotificationHours? h) =>
    h == null || h.from == h.to ? l.notifyAlways : l.notifyBetween(_hm(h.from), _hm(h.to));

/// Row showing a notification window; tapping it edits the window.
class NotificationHoursTile extends StatelessWidget {
  const NotificationHoursTile({
    super.key,
    required this.hours,
    required this.onChanged,
    this.inherited,
  });

  /// The window set at this level (app, or host); null = none.
  final NotificationHours? hours;

  /// For a host: the app-wide window it falls back to. Null for the app row.
  final NotificationHours? Function()? inherited;
  final ValueChanged<HoursChoice> onChanged;

  bool get _hostLevel => inherited != null;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final subtitle = _hostLevel && hours == null
        ? l.notifyUsesApp(hoursLabel(l, inherited!()))
        : hoursLabel(l, hours);
    return ListTile(
      key: const Key('notification_hours'),
      leading: const Icon(Icons.schedule),
      title: Text(l.notifyHours),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        final choice = await showDialog<HoursChoice>(
          context: context,
          builder: (_) => _HoursDialog(initial: hours, hostLevel: _hostLevel),
        );
        if (choice != null) onChanged(choice);
      },
    );
  }
}

enum _Mode { inherit, always, window }

class _HoursDialog extends StatefulWidget {
  const _HoursDialog({required this.initial, required this.hostLevel});
  final NotificationHours? initial;
  final bool hostLevel;

  @override
  State<_HoursDialog> createState() => _HoursDialogState();
}

class _HoursDialogState extends State<_HoursDialog> {
  late _Mode _mode = switch (widget.initial) {
    null => widget.hostLevel ? _Mode.inherit : _Mode.always,
    final h when h.from == h.to => _Mode.always,
    _ => _Mode.window,
  };
  late int _from = widget.initial?.from ?? 8 * 60;
  late int _to = widget.initial?.to ?? 21 * 60;

  Future<void> _pick(bool from) async {
    final m = from ? _from : _to;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t == null) return;
    setState(() => from ? _from = t.hour * 60 + t.minute : _to = t.hour * 60 + t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget option(_Mode m, String title) =>
        RadioListTile<_Mode>(contentPadding: EdgeInsets.zero, value: m, title: Text(title));
    return AlertDialog(
      title: Text(l.notifyHours),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.notifyHoursBody),
          const SizedBox(height: 8),
          RadioGroup<_Mode>(
            groupValue: _mode,
            onChanged: (v) => setState(() => _mode = v ?? _mode),
            child: Column(
              children: [
                if (widget.hostLevel) option(_Mode.inherit, l.notifyUseAppSetting),
                option(_Mode.always, l.notifyAlways),
                option(_Mode.window, l.notifyOnlyBetween),
              ],
            ),
          ),
          if (_mode == _Mode.window)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('notify_from'),
                    onPressed: () => _pick(true),
                    child: Text('${l.notifyFrom} ${_hm(_from)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    key: const Key('notify_to'),
                    onPressed: () => _pick(false),
                    child: Text('${l.notifyTo} ${_hm(_to)}'),
                  ),
                ),
              ],
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(
          key: const Key('notify_save'),
          onPressed: () => Navigator.of(context).pop(switch (_mode) {
            _Mode.inherit => const InheritHours(),
            _Mode.always => const SetHours(null),
            _Mode.window => SetHours(NotificationHours(_from, _to)),
          }),
          child: Text(l.save),
        ),
      ],
    );
  }
}
