import '../entities/screen_block.dart';

const _denyWords = {
  'no',
  'reject',
  'deny',
  'skip',
  'cancel',
  'decline',
  'abort',
  'block',
  "don't",
  'never',
};
const _allowWords = {'yes', 'allow', 'approve', 'run', 'proceed', 'accept', 'ok', 'always'};
const _alwaysMarkers = [
  "don't ask again",
  'always',
  'allow all',
  'approve all',
  'this session',
  'the session',
  'rest of',
  'in the future',
  'this conversation',
  'allowlist',
  'allow list',
];

/// Guesses what answering with [label] means, from its wording.
ChoiceKind classifyChoice(String label) {
  final lower = label.trim().toLowerCase();
  final first = _firstWord(lower);
  if (_denyWords.contains(first)) return ChoiceKind.deny;
  if (lower.contains('allowlist') || lower.contains('allow list')) return ChoiceKind.allowAlways;
  if (!_allowWords.contains(first)) return ChoiceKind.other;
  if (_alwaysMarkers.any(lower.contains)) return ChoiceKind.allowAlways;
  return ChoiceKind.allow;
}

String _firstWord(String lower) {
  var end = 0;
  while (end < lower.length) {
    final c = lower.codeUnitAt(end);
    final letter = (c >= 0x61 && c <= 0x7a) || c == 0x27 /* ' */;
    if (!letter) break;
    end++;
  }
  return lower.substring(0, end);
}
