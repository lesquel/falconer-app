import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/domain/entities/event_mapper.dart';

Map<String, Object?> wire({Object? id = 'ev_1-A', String title = 'Run?', String summary = ''}) => {
  'id': id,
  'kind': 'approval_required',
  'seq': 1,
  'ts': 1,
  'agent': 'claude',
  'title': title,
  'summary': summary,
  'pane': 'p1',
};

void main() {
  test('event ids must be b64u: no dot segments or slashes', () {
    expect(eventFromWire(wire(), hostId: 'h1'), isNotNull);
    for (final bad in ['../inbox', 'a/b', '..', 'a b', 'é', '', 'a' * 129]) {
      expect(
        eventFromWire(wire(id: bad), hostId: 'h1'),
        isNull,
        reason: bad,
      );
    }
  });

  test('titles and summaries lose bidi, zero-width and C1 characters', () {
    final e = eventFromWire(
      wire(title: 'rm \u202Efdp.exe\u200B', summary: 'line1\nline2\u0085\u2029x'),
      hostId: 'h1',
    )!;
    expect(e.title, 'rm fdp.exe');
    expect(e.summary, 'line1\nline2x');
  });

  test('cut text is marked with an ellipsis', () {
    final e = eventFromWire(
      wire(title: 't' * 300, summary: 's' * 5000),
      hostId: 'h1',
    )!;
    expect(e.title.runes.length, 200);
    expect(e.title.endsWith('…'), isTrue);
    expect(e.summary.runes.length, maxSummaryChars);
    expect(e.summary.endsWith('…'), isTrue);
  });

  test('a summary longer than a notification is kept for the confirm screen', () {
    final e = eventFromWire(wire(summary: 'x' * 900), hostId: 'h1')!;
    expect(e.summary.length, 900);
  });
}
