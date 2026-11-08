import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';
import 'package:openmosh/features/inbox/presentation/views/event_confirm_view.dart';
import 'package:openmosh/features/inbox/presentation/views/inbox_view.dart';

import '../support/l10n_app.dart';

Widget app(Widget child) => l10nApp(home: Scaffold(body: child));

InboxEvent event({InboxStatus? status}) {
  final e = InboxEvent.received(
    id: 'ev1',
    hostId: 'h1',
    seq: 1,
    agent: 'claude',
    kind: EventKind.approvalRequired,
    title: 'Run tests?',
    summary: 'cargo test --all',
    pane: 'p1',
    at: DateTime.utc(2026),
  );
  return status == InboxStatus.resolved ? e.resolvedElsewhere() : e;
}

void main() {
  testWidgets('event confirm sends allow, deny and text answers', (t) async {
    final calls = <String>[];
    await t.pumpWidget(
      app(
        EventConfirmView(
          event: event(),
          hostAlias: 'work',
          busy: false,
          suggested: ResponseKind.allow,
          onAllow: () => calls.add('allow'),
          onDeny: () => calls.add('deny'),
          onText: (s) => calls.add('text:$s'),
          onOpenTerminal: () {},
        ),
      ),
    );
    expect(find.text('cargo test --all'), findsOneWidget);
    expect(find.textContaining('Confirm below'), findsOneWidget);
    await t.tap(find.byKey(const Key('approve')));
    await t.tap(find.byKey(const Key('deny')));
    await t.enterText(find.byType(TextField), 'use --release');
    await t.tap(find.text('Send reply'));
    expect(calls, ['allow', 'deny', 'text:use --release']);
  });

  testWidgets('resolved events cannot be answered again', (t) async {
    var called = false;
    await t.pumpWidget(
      app(
        EventConfirmView(
          event: event(status: InboxStatus.resolved),
          hostAlias: 'work',
          busy: false,
          onAllow: () => called = true,
          onDeny: () => called = true,
          onText: (_) => called = true,
          onOpenTerminal: () {},
        ),
      ),
    );
    await t.tap(find.byKey(const Key('approve')));
    expect(called, isFalse);
    expect(find.text('Already answered.'), findsOneWidget);
  });

  testWidgets('inbox view shows status badges', (t) async {
    await t.pumpWidget(app(InboxView(events: [event()], hostAlias: (_) => 'work', onOpen: (_) {})));
    expect(find.text('Run tests?'), findsOneWidget);
    expect(find.text('needs approval'), findsOneWidget);
  });

  testWidgets('a long request starts cut and the full text is one tap away', (t) async {
    final long = 'a' * 250 + 'END';
    await t.pumpWidget(
      app(
        EventConfirmView(
          event: InboxEvent.received(
            id: 'ev1',
            hostId: 'h1',
            seq: 1,
            agent: 'claude',
            kind: EventKind.approvalRequired,
            title: 'Run?',
            summary: long,
            pane: 'p1',
            at: DateTime.utc(2026),
          ),
          hostAlias: 'work',
          busy: false,
          onAllow: () {},
          onDeny: () {},
          onText: (_) {},
          onOpenTerminal: () {},
        ),
      ),
    );
    expect(find.textContaining('END'), findsNothing);
    expect(find.textContaining('…'), findsOneWidget);
    await t.tap(find.text('Show full text'));
    await t.pump();
    expect(find.text(long), findsOneWidget);
  });
}
