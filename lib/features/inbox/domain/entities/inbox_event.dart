/// Agent event in the inbox and its state machine.
library;

enum EventKind {
  approvalRequired('approval_required'),
  question('question'),
  done('done'),
  resolved('resolved');

  const EventKind(this.wire);
  final String wire;

  static EventKind? parse(String? wire) {
    for (final k in values) {
      if (k.wire == wire) return k;
    }
    return null;
  }

  bool get actionable => this == approvalRequired || this == question;
}

enum InboxStatus { pending, info, responding, resolved, failed }

enum ResponseKind { allow, deny, text }

final class InvalidTransition implements Exception {
  const InvalidTransition(this.from, this.action);
  final InboxStatus from;
  final String action;

  @override
  String toString() => 'InvalidTransition($action from $from)';
}

final class InboxEvent {
  const InboxEvent({
    required this.id,
    required this.hostId,
    required this.seq,
    required this.agent,
    required this.kind,
    required this.title,
    required this.summary,
    required this.pane,
    required this.at,
    required this.status,
    this.response,
  });

  factory InboxEvent.received({
    required String id,
    required String hostId,
    required int seq,
    required String agent,
    required EventKind kind,
    required String title,
    required String summary,
    required String pane,
    required DateTime at,
  }) => InboxEvent(
    id: id,
    hostId: hostId,
    seq: seq,
    agent: agent,
    kind: kind,
    title: title,
    summary: summary,
    pane: pane,
    at: at,
    status: kind.actionable ? InboxStatus.pending : InboxStatus.info,
  );

  final String id;
  final String hostId;
  final int seq;
  final String agent;
  final EventKind kind;
  final String title;
  final String summary;
  final String pane;
  final DateTime at;
  final InboxStatus status;
  final ResponseKind? response;

  bool get needsAction => status == InboxStatus.pending || status == InboxStatus.failed;

  InboxEvent startResponding(ResponseKind kind) {
    if (!needsAction) throw InvalidTransition(status, 'respond');
    return _with(InboxStatus.responding, kind);
  }

  InboxEvent responseSucceeded() {
    if (status != InboxStatus.responding) throw InvalidTransition(status, 'succeed');
    return _with(InboxStatus.resolved, response);
  }

  InboxEvent responseFailed() {
    if (status != InboxStatus.responding) throw InvalidTransition(status, 'fail');
    return _with(InboxStatus.failed, response);
  }

  /// Another device answered, or the host reported the event resolved.
  /// [atSeq] is the seq of the resolving message, kept so it is not replayed.
  InboxEvent resolvedElsewhere({int? atSeq}) =>
      _with(InboxStatus.resolved, response, seq: _maxSeq(atSeq));

  /// Same event delivered again (push + sync): keep the furthest state and
  /// the highest seq seen for it.
  InboxEvent mergeIncoming(InboxEvent incoming) {
    final keep = _rank(incoming.status) > _rank(status) ? incoming : this;
    return keep._with(keep.status, keep.response, seq: _maxSeq(incoming.seq));
  }

  int _maxSeq(int? other) => other != null && other > seq ? other : seq;

  static int _rank(InboxStatus s) => switch (s) {
    InboxStatus.pending || InboxStatus.info => 0,
    InboxStatus.failed => 1,
    InboxStatus.responding => 2,
    InboxStatus.resolved => 3,
  };

  InboxEvent _with(InboxStatus s, ResponseKind? r, {int? seq}) => InboxEvent(
    id: id,
    hostId: hostId,
    seq: seq ?? this.seq,
    agent: agent,
    kind: kind,
    title: title,
    summary: summary,
    pane: pane,
    at: at,
    status: s,
    response: r,
  );
}
