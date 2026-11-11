import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/agent_view/domain/usecases/screen_history.dart';

List<String> lines(int from, int to) => [for (var i = from; i < to; i++) 'line $i'];

void main() {
  test('the first read is the buffer', () {
    final h = ScreenHistory();
    expect(h.merge(lines(0, 10), requested: 1000), isTrue);
    expect(h.lines, lines(0, 10));
  });

  test('a read that overlaps the tail keeps the earlier lines and adds the new ones', () {
    final h = ScreenHistory()..merge(lines(0, 1000), requested: 1000);
    expect(h.merge(lines(800, 1100), requested: 300), isTrue);
    expect(h.lines, lines(0, 1100));
  });

  test('the same read again changes nothing', () {
    final h = ScreenHistory()..merge(lines(0, 50), requested: 1000);
    expect(h.merge(lines(0, 50), requested: 300), isFalse);
    expect(h.lines, lines(0, 50));
  });

  test('a redrawn last line (a spinner, a status line) replaces only that line', () {
    final h = ScreenHistory()..merge([...lines(0, 20), '⠋ Thinking… 3s'], requested: 1000);
    h.merge([...lines(5, 20), '⠙ Thinking… 4s'], requested: 300);
    expect(h.lines, [...lines(0, 20), '⠙ Thinking… 4s']);
    h.merge([...lines(5, 20), 'Done.', '> '], requested: 300);
    expect(h.lines, [...lines(0, 20), 'Done.', '> ']);
  });

  test('blank leading lines do not anchor the read anywhere', () {
    final h = ScreenHistory()..merge(['a', '', '', 'b', 'c'], requested: 1000);
    h.merge(['', '', 'b', 'c', 'd'], requested: 300);
    expect(h.lines, ['a', '', '', 'b', 'c', 'd']);
  });

  test('a full read with no overlap is appended after a gap mark', () {
    final h = ScreenHistory()..merge(lines(0, 300), requested: 300);
    h.merge(lines(5000, 5300), requested: 300);
    expect(h.lines, [...lines(0, 300), historyGapLine, ...lines(5000, 5300)]);
  });

  test('a whole-pane read with no overlap (a cleared screen) replaces only the last read', () {
    final h = ScreenHistory()
      ..merge(lines(0, 300), requested: 300)
      ..merge(lines(5000, 5300), requested: 300);
    // A full-screen program redraws everything: fewer lines than asked.
    h.merge(['top', 'htop-like screen'], requested: 300);
    expect(h.lines, [...lines(0, 300), historyGapLine, 'top', 'htop-like screen']);
    h.merge(['top', 'redrawn screen'], requested: 300);
    expect(h.lines, [...lines(0, 300), historyGapLine, 'top', 'redrawn screen']);
  });

  test('load earlier adds the earlier lines in front and keeps the buffer', () {
    final h = ScreenHistory()
      ..merge(lines(1000, 2000), requested: 1000)
      ..merge(lines(1800, 2100), requested: 300);
    expect(h.merge(lines(100, 2100), requested: 2000), isTrue);
    expect(h.lines, lines(100, 2100));
  });

  test('the buffer is capped at its newest lines', () {
    final h = ScreenHistory(cap: 100)..merge(lines(0, 80), requested: 1000);
    h.merge(lines(60, 150), requested: 300);
    expect(h.lines, lines(50, 150));
    expect(h.lines.length, 100);
    expect(ScreenHistory().cap, maxHistoryLines);
    expect(maxHistoryLines, 5000);
  });
}
