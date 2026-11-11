/// What the graphic view has seen of one pane while it is open: each read
/// of the pane's last lines is merged into it instead of replacing it, so
/// nothing already shown is lost (S17).
library;

/// Most lines kept; the oldest go first.
const maxHistoryLines = 5000;

/// Marks where a read did not overlap what was already seen (more output
/// than one read returns arrived in between).
const historyGapLine = '⋯';

/// Lines compared to find where a read starts in the buffer.
const _anchorLines = 8;

/// Last lines of the buffer a new read may show redrawn.
const _redrawnLines = 2;

final class ScreenHistory {
  ScreenHistory({this.cap = maxHistoryLines});

  final int cap;
  List<String> _lines = const [];

  /// Where the latest read starts in [lines]; a read that replaces the
  /// screen (a cleared terminal, a full-screen program) replaces from here.
  int _tailStart = 0;

  List<String> get lines => _lines;

  /// Merges [fresh], the pane's last lines, read asking for [requested]
  /// lines. Returns whether [lines] changed.
  ///
  /// - [fresh] starts inside the buffer: everything before that point stays
  ///   and [fresh] replaces the rest (new output, a redrawn status line).
  /// - The buffer starts inside [fresh] (a longer "load earlier" read): the
  ///   earlier lines are added in front; the buffer stays as it is.
  /// - No overlap and [fresh] is the whole pane (fewer lines than
  ///   [requested]): the screen was redrawn, it replaces the latest read.
  /// - No overlap otherwise: appended after a [historyGapLine].
  bool merge(List<String> fresh, {required int requested}) {
    final before = _lines;
    if (_lines.isEmpty) {
      _set(fresh, 0);
    } else if (_startInBuffer(fresh) case final start?) {
      _set([..._lines.take(start), ...fresh], start);
    } else if (_bufferStartInFresh(fresh) case final at? when at > 0) {
      _set([...fresh.take(at), ..._lines], _tailStart + at);
    } else if (fresh.length < requested) {
      _set([..._lines.take(_tailStart), ...fresh], _tailStart);
    } else {
      final start = _lines.length + 1;
      _set([..._lines, historyGapLine, ...fresh], start);
    }
    return !_same(before, _lines);
  }

  void clear() {
    _lines = const [];
    _tailStart = 0;
  }

  void _set(List<String> lines, int tailStart) {
    final drop = lines.length > cap ? lines.length - cap : 0;
    _lines = List.unmodifiable(drop > 0 ? lines.sublist(drop) : lines);
    _tailStart = (tailStart - drop).clamp(0, _lines.length);
  }

  /// Index in the buffer where [fresh] begins, matched on its first
  /// non-blank lines (blank lines alone match anywhere); the latest match.
  int? _startInBuffer(List<String> fresh) {
    final s = _firstText(fresh);
    if (s == null) return null;
    final anchor = fresh.sublist(s, (s + _anchorLines).clamp(0, fresh.length));
    final i = _lastIndexOf(_lines, anchor) ?? _lastTailOverlap(anchor);
    return i == null ? null : (i - s).clamp(0, _lines.length);
  }

  /// Index in [fresh] where the buffer begins (matched like
  /// [_startInBuffer]).
  int? _bufferStartInFresh(List<String> fresh) {
    final s = _firstText(_lines);
    if (s == null) return null;
    final anchor = _lines.sublist(s, (s + _anchorLines).clamp(0, _lines.length));
    final i = _lastIndexOf(fresh, anchor);
    return i == null || i < s ? null : i - s;
  }

  /// A short overlap: the anchor's first lines (at least two, so one common
  /// line is not taken for an overlap) are the buffer's last ones, up to
  /// its last [_redrawnLines] lines, which may have been redrawn (a prompt
  /// that got typed into, a status line). The longest overlap wins.
  int? _lastTailOverlap(List<String> anchor) {
    final from = _lines.length - anchor.length - _redrawnLines;
    for (var i = from < 0 ? 0 : from; i <= _lines.length - 2; i++) {
      var m = 0;
      while (m < anchor.length && i + m < _lines.length && _lines[i + m] == anchor[m]) {
        m++;
      }
      if (m >= 2 && i + m >= _lines.length - _redrawnLines) return i;
    }
    return null;
  }

  static int? _firstText(List<String> lines) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) return i;
    }
    return null;
  }

  static int? _lastIndexOf(List<String> hay, List<String> needle) {
    for (var i = hay.length - needle.length; i >= 0; i--) {
      var ok = true;
      for (var k = 0; k < needle.length; k++) {
        if (hay[i + k] != needle[k]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return null;
  }

  static bool _same(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
