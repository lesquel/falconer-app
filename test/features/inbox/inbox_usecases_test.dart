import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/hosts/domain/entities/host.dart';
import 'package:openmosh/features/hosts/domain/usecases/host_connections.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';
import 'package:openmosh/features/inbox/domain/entities/push_endpoint.dart';
import 'package:openmosh/features/inbox/domain/repositories/inbox_ports.dart';
import 'package:openmosh/features/inbox/domain/usecases/inbox_usecases.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ssh/domain/ssh_ports.dart';

import '../../support/fakes.dart';

class MemInbox implements InboxRepository {
  final Map<String, InboxEvent> rows = {};
  @override
  Future<InboxEvent?> byId(String hostId, String id) async => rows['$hostId/$id'];
  @override
  Future<int> maxSeq(String hostId) async =>
      rows.values.where((e) => e.hostId == hostId).fold<int>(0, (m, e) => e.seq > m ? e.seq : m);
  @override
  Future<int> pendingCount() async => rows.values.where((e) => e.needsAction).length;
  @override
  Future<void> upsert(InboxEvent e) async => rows['${e.hostId}/${e.id}'] = e;
  @override
  Stream<List<InboxEvent>> watchAll() => const Stream.empty();
}

class FakeOpener implements PushOpener {
  Map<String, Object?>? next;
  @override
  Future<Map<String, Object?>> open(Host host, List<int> body) async {
    if (next == null) throw const PushFailure('bad');
    return next!;
  }
}

class FakeNotifier implements EventNotifier {
  final shown = <(String, String, bool)>[];
  final cancelled = <String>[];
  @override
  Future<void> show(InboxEvent e, {required String hostAlias, required bool preview}) async =>
      shown.add((e.id, hostAlias, preview));
  @override
  Future<void> cancel(String hostId, String eventId) async => cancelled.add(eventId);
}

Map<String, Object?> wire({String id = 'ev1', String kind = 'approval_required', int seq = 5}) => {
  'id': id,
  'seq': seq,
  'host': 'work',
  'agent': 'claude',
  'kind': kind,
  'title': 'Allow?',
  'summary': 'rm build/',
  'pane': 'p1',
  'ts': 1700000000,
};

void main() {
  late FakeHostRepository hosts;
  late MemInbox inbox;
  late FakeOpener opener;
  late FakeNotifier notifier;
  late HandlePushMessage handle;
  var previews = false;

  setUp(() async {
    hosts = FakeHostRepository();
    await hosts.save(testHost(deviceId: 'kid1', hpk: 'AAAA', hookPath: '/h'));
    inbox = MemInbox();
    opener = FakeOpener();
    notifier = FakeNotifier();
    previews = false;
    handle = HandlePushMessage(
      hosts: hosts,
      inbox: inbox,
      opener: opener,
      notifier: notifier,
      previews: () async => previews,
      kidOf: (b) => (jsonDecode(utf8.decode(b)) as Map)['kid'] as String?,
    );
  });

  List<int> body(String kid) => utf8.encode(jsonEncode({'v': 1, 'kid': kid, 'n': 'x', 'c': 'y'}));

  test('a new event is stored pending and notified without preview by default', () async {
    opener.next = wire();
    final e = await handle(body('kid1'));
    expect(e!.status, InboxStatus.pending);
    expect(notifier.shown.single, ('ev1', 'work', false));
    previews = true;
    opener.next = wire(id: 'ev2');
    await handle(body('kid1'));
    expect(notifier.shown.last, ('ev2', 'work', true));
  });

  test('unknown kid or undecryptable body is discarded silently', () async {
    opener.next = wire();
    expect(await handle(body('other')), isNull);
    opener.next = null;
    expect(await handle(body('kid1')), isNull);
    expect(inbox.rows, isEmpty);
    expect(notifier.shown, isEmpty);
  });

  test('a push with a bad ts, seq or kind type is discarded, never thrown', () async {
    final bad = <Map<String, Object?>>[
      wire()..['ts'] = 1 << 62,
      wire()..['ts'] = -1,
      wire()..['ts'] = '1700000000',
      wire()..['seq'] = -1,
      wire()..['seq'] = 1.5,
      wire()..['kind'] = 7,
      wire()..['id'] = 7,
    ];
    for (final m in bad) {
      opener.next = m;
      expect(await handle(body('kid1')), isNull, reason: '$m');
    }
    expect(inbox.rows, isEmpty);
    expect(notifier.shown, isEmpty);
  });

  test('a push without ts or seq still maps with defaults', () async {
    opener.next = wire()
      ..remove('ts')
      ..remove('seq');
    final e = await handle(body('kid1'));
    expect(e!.seq, 0);
    expect(e.at, DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
  });

  test('a duplicate push is not notified twice', () async {
    opener.next = wire();
    await handle(body('kid1'));
    await handle(body('kid1'));
    expect(notifier.shown.length, 1);
  });

  test('resolved push resolves the event and clears its notification', () async {
    opener.next = wire();
    await handle(body('kid1'));
    opener.next = wire(kind: 'resolved');
    final r = await handle(body('kid1'));
    expect(r!.status, InboxStatus.resolved);
    expect(notifier.cancelled, ['ev1']);
  });

  group('RespondToEvent', () {
    late FakeConnection conn;
    late RespondToEvent respond;
    ExecOutput Function(String, List<int>?) reply = (_, _) => ok({'resolved': true});

    setUp(() async {
      opener.next = wire();
      await handle(body('kid1'));
      conn = FakeConnection((c, s) => reply(c, s));
      respond = RespondToEvent(
        inbox: inbox,
        connections: HostConnections(
          hosts: hosts,
          vault: FakeVault(),
          connector: FakeConnector(() => conn),
        ),
        notifier: notifier,
      );
    });

    test('approve runs the respond command and resolves', () async {
      reply = (_, _) => ok({'resolved': true});
      final done = await respond('h1', 'ev1', ResponseKind.allow);
      expect(conn.scripts.single, "'/h' 'respond' 'ev1' '--action' 'allow' '--json'\n");
      expect(done.status, InboxStatus.resolved);
      expect(notifier.cancelled, ['ev1']);
    });

    test('host error leaves the event failed and retryable', () async {
      reply = (_, _) =>
          text('{"ok":false,"error":{"code":"pane_gone","message":"pane closed"}}', code: 1);
      await expectLater(respond('h1', 'ev1', ResponseKind.deny), throwsA(isA<HookFailure>()));
      expect((await inbox.byId('h1', 'ev1'))!.status, InboxStatus.failed);
      reply = (_, _) => ok(null);
      expect(
        (await respond('h1', 'ev1', ResponseKind.text, text: 'yes')).status,
        InboxStatus.resolved,
      );
    });
  });

  test('sync asks for events after the last seq and merges them', () async {
    opener.next = wire(seq: 5);
    await handle(body('kid1'));
    final conn = FakeConnection(
      (_, _) => ok([wire(id: 'ev1', seq: 5)..['status'] = 'resolved', wire(id: 'ev9', seq: 9)]),
    );
    final sync = SyncInbox(
      inbox: inbox,
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
    );
    expect(await sync('h1'), 2);
    expect(conn.scripts.single, contains("'--since' '5'"));
    expect((await inbox.byId('h1', 'ev1'))!.status, InboxStatus.resolved);
    expect((await inbox.byId('h1', 'ev9'))!.status, InboxStatus.pending);
  });

  test('sync reads the hook inbox page shape', () async {
    final conn = FakeConnection(
      (_, _) => ok({
        'events': [
          {
            'id': '-AbC',
            'seq': 12,
            'source': 'herdr',
            'agent': 'claude',
            'kind': 'question',
            'status': 'pending',
            'title': 'Which DB?',
            'summary': 'pick one',
            'pane': null,
            'runtime': 'herdr',
            'created_at': 1762500000,
            'resolved_at': null,
            'resolution': null,
          },
        ],
        'last_seq': 12,
      }),
    );
    final sync = SyncInbox(
      inbox: inbox,
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
    );
    expect(await sync('h1'), 1);
    final e = (await inbox.byId('h1', '-AbC'))!;
    expect(e.kind, EventKind.question);
    expect(e.at, DateTime.fromMillisecondsSinceEpoch(1762500000 * 1000, isUtc: true));
    expect(e.pane, '');
  });

  test('ids starting with a hyphen are answered (hook ids are b64u)', () async {
    opener.next = wire(id: '-x1');
    await handle(body('kid1'));
    final conn = FakeConnection((_, _) => ok(null));
    await RespondToEvent(
      inbox: inbox,
      connections: HostConnections(
        hosts: hosts,
        vault: FakeVault(),
        connector: FakeConnector(() => conn),
      ),
      notifier: notifier,
    )('h1', '-x1', ResponseKind.allow);
    expect(conn.scripts.single, "'/h' 'respond' '-x1' '--action' 'allow' '--json'\n");
  });

  test('endpoint rule: https anywhere, http only inside the tailnet', () {
    expect(isAllowedPushEndpoint('https://ntfy.sh/up1'), isTrue);
    expect(isAllowedPushEndpoint('http://ntfy.tail1.ts.net/up1'), isTrue);
    expect(isAllowedPushEndpoint('http://100.90.1.2:8080/up1'), isTrue);
    expect(isAllowedPushEndpoint('http://ntfy.sh/up1'), isFalse);
    expect(isAllowedPushEndpoint('ftp://x/y'), isFalse);
    expect(isAllowedPushEndpoint('https://user:pw@ntfy.sh/up'), isFalse);
  });
}
