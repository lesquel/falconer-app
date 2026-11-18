import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/agent_view/domain/detectors/detector_registry.dart';

/// Status fragments every detector drops (mirrors `_commonNoise`).
const _common = [
  '? for shortcuts',
  'esc to interrupt',
  'esc to cancel',
  'press enter to confirm',
  'ctrl+o to',
  'shift+tab to cycle',
  '↑↓ navigate',
];

/// The matcher [AgentDetector.isNoise] used before it stopped compiling a
/// case-insensitive alternation: the reference its answers must keep.
bool Function(String) _reference(List<String> noise) {
  final re = RegExp([..._common, ...noise].map(RegExp.escape).join('|'), caseSensitive: false);
  return (t) => t.isNotEmpty && t.length <= 160 && re.hasMatch(t);
}

String _mixed(String s) => String.fromCharCodes([
  for (var i = 0; i < s.length; i++) i.isEven ? s.toUpperCase().codeUnitAt(i) : s.codeUnitAt(i),
]);

void main() {
  const ids = [
    null,
    'claude',
    'codex',
    'pi',
    'gemini',
    'kiro',
    'opencode',
    'copilot',
    'cursor',
    'amp',
    'aider',
    'other',
  ];

  for (final id in ids) {
    test('isNoise answers like the case-insensitive regex for ${id ?? 'shell'}', () {
      final detector = detectorFor(id);
      final ref = _reference(detector.noise);
      final fragments = [
        ..._common,
        ...detector.noise,
        'accept edits on',
        'context left',
        'tokens:',
      ];
      final samples = <String>[
        '',
        'plain agent text',
        'x' * 161,
        '${'x' * 150} esc to cancel',
        '${'x' * 140} esc to cancel',
        // Non-ASCII letters never fold to ASCII ones in a non-unicode regex.
        'ESC TO İNTERRUPT',
        'eſc to cancel',
        'ctrl+O to expand',
        'Keep ctrl+o to',
        'Ünïcödé ? FOR SHORTCUTS',
        for (final f in fragments) ...[
          f,
          f.toUpperCase(),
          _mixed(f),
          '  ⏵⏵ ${f.toUpperCase()} (shift+tab)',
          'prefix $f suffix',
          f.substring(0, f.length - 1),
        ],
      ];
      for (final s in samples) {
        expect(detector.isNoise(s), ref(s), reason: s);
      }
    });
  }
}
