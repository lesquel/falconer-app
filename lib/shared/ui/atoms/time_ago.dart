/// Short relative time for cards: "12 s ago", "5 min ago", "3 h ago", "2 d ago".
String timeAgo(DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inSeconds < 5) return 'just now';
  if (d.inMinutes < 1) return '${d.inSeconds} s ago';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

/// Greeting for the hour of the day.
String greetingFor(DateTime now) => switch (now.hour) {
  >= 5 && < 12 => 'Good morning',
  >= 12 && < 19 => 'Good afternoon',
  _ => 'Good evening',
};
