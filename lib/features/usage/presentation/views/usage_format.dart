/// Compact number and duration text for the usage screen.
library;

/// `850`, `1.2K`, `850K`, `1.2M`, `85M`, `3B`. One decimal below 10 of a
/// unit; [decimal] is the locale's decimal separator.
String compactTokens(int n, {String decimal = '.'}) {
  if (n < 1000) return '$n';
  const units = ['K', 'M', 'B', 'T'];
  var value = n / 1000;
  var unit = 0;
  while (unit < units.length - 1 && value.round() >= 1000) {
    value /= 1000;
    unit++;
  }
  final text = value < 9.95
      ? value.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')
      : value.round().toString();
  return '${text.replaceFirst('.', decimal)}${units[unit]}';
}

/// `45m`, `2h 10m`, `3d 4h`; at least `1m`.
String shortDuration(Duration d) {
  final days = d.inDays;
  final hours = d.inHours % 24;
  final minutes = d.inMinutes % 60;
  if (days > 0) return hours > 0 ? '${days}d ${hours}h' : '${days}d';
  if (d.inHours > 0) return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
  return '${minutes < 1 ? 1 : minutes}m';
}

/// Brand names of the agents the hook knows; others show their id.
String agentDisplayName(String agent) => switch (agent) {
  'claude' => 'Claude Code',
  'codex' => 'Codex',
  'opencode' => 'OpenCode',
  'gemini' => 'Gemini CLI',
  'pi' => 'Pi',
  _ => agent,
};
