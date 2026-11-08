/// The daily window in which notifications may sound. Outside it a push is
/// still stored in the inbox, without a system notification.
library;

final class NotificationHours {
  /// Minutes after midnight, 0..1439. `from == to` means all day. A window
  /// may cross midnight (22:00–07:00).
  const NotificationHours(this.from, this.to)
    : assert(from >= 0 && from < 1440),
      assert(to >= 0 && to < 1440);

  final int from;
  final int to;

  bool allows(DateTime at) {
    if (from == to) return true;
    final m = at.hour * 60 + at.minute;
    return from < to ? m >= from && m < to : m >= from || m < to;
  }

  /// `from-to` in minutes, e.g. `480-1260`.
  String encode() => '$from-$to';

  static NotificationHours? parse(String? raw) {
    final parts = raw?.split('-');
    if (parts == null || parts.length != 2) return null;
    final from = int.tryParse(parts[0]);
    final to = int.tryParse(parts[1]);
    if (from == null || to == null) return null;
    if (from < 0 || from >= 1440 || to < 0 || to >= 1440) return null;
    return NotificationHours(from, to);
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationHours && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
