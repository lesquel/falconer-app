import '../../../l10n/l10n.dart';

/// Short relative time for cards: "12 s ago", "5 min ago", "3 h ago", "2 d ago".
String timeAgo(AppLocalizations l, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inSeconds < 5) return l.timeJustNow;
  if (d.inMinutes < 1) return l.timeSecondsAgo(d.inSeconds);
  if (d.inHours < 1) return l.timeMinutesAgo(d.inMinutes);
  if (d.inDays < 1) return l.timeHoursAgo(d.inHours);
  return l.timeDaysAgo(d.inDays);
}

/// Greeting for the hour of the day.
String greetingFor(AppLocalizations l, DateTime now) => switch (now.hour) {
  >= 5 && < 12 => l.greetingMorning,
  >= 12 && < 19 => l.greetingAfternoon,
  _ => l.greetingEvening,
};
