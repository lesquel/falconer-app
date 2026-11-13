import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/webpush/domain/entities/webpush_delivery.dart';
import 'package:openmosh/features/webpush/domain/entities/webpush_registration.dart';
import 'package:openmosh/features/webpush/domain/repositories/webpush_store.dart';
import 'package:openmosh/features/webpush/domain/usecases/webpush_sync.dart';
import 'package:openmosh/shared/domain/b64u.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';

import '../../support/fakes.dart';

class MemStore implements WebPushStore {
  WebPushRegistration? reg;
  final Map<String, WebPushDelivery> del = {};
  @override
  Future<WebPushRegistration?> registration() async => reg;
  @override
  Future<void> saveRegistration(WebPushRegistration r) async => reg = r;
  @override
  Future<void> clearRegistration() async => reg = null;
  @override
  Future<Map<String, WebPushDelivery>> deliveries() async => Map.of(del);
  @override
  Future<void> setDelivery(String id, WebPushDelivery? d) async =>
      d == null ? del.remove(id) : del[id] = d;
  @override
  Future<void> clearDeliveries() async => del.clear();
}

WebPushRegistration reg(int seed) => WebPushRegistration.parse(
  b64uEncode(
    utf8.encode(
      jsonEncode({
        'v': 1,
        'endpoint': 'https://web.push.apple.com/$seed',
        'p256dh': b64uEncode(List.filled(65, seed)),
        'auth': b64uEncode(List.filled(16, seed)),
        'vapid_pub': b64uEncode(List.filled(65, seed)),
        'vapid_priv': b64uEncode(List.filled(32, seed)),
        'sub': 'mailto:a@b.c',
      }),
    ),
  ),
);

void main() {
  late MemStore store;
  late FakeHostRepository hosts;
  late WebPushSync sync;
  late List<(String, List<String>, List<int>?)> calls;
  Map<String, Object> failWith = {};

  Future<Object?> run(String hostId, HookCommand cmd, {List<int>? stdin}) async {
    calls.add((hostId, cmd.argv, stdin));
    final e = failWith[hostId];
    if (e != null) throw e;
    return <String, Object?>{};
  }

  setUp(() async {
    store = MemStore();
    hosts = FakeHostRepository();
    await hosts.save(testHost(id: 'a', deviceId: 'da', hpk: 'k'));
    await hosts.save(testHost(id: 'b', deviceId: 'db', hpk: 'k'));
    await hosts.save(testHost(id: 'unpaired'));
    sync = WebPushSync(store: store, hosts: hosts);
    calls = [];
    failWith = {};
  });

  test('delivers the JSON on stdin to every paired host', () async {
    final r = reg(1);
    await sync.activate(r);
    final out = await sync.syncAll(run);
    expect(out, {'a': WebPushHostResult.delivered, 'b': WebPushHostResult.delivered});
    expect(
      calls.map((c) => c.$2),
      everyElement(['devices', 'set-webpush', anyOf('da', 'db'), '--json']),
    );
    expect(jsonDecode(utf8.decode(calls.first.$3!)), r.toJson());
    expect(store.del['a']!.hash, r.hash);
  });

  test('skips an already delivered hash, re-sends after a change', () async {
    await sync.activate(reg(1));
    await sync.syncAll(run);
    calls.clear();
    final again = await sync.syncAll(run);
    expect(again.values, everyElement(WebPushHostResult.alreadyDelivered));
    expect(calls, isEmpty);
    await sync.activate(reg(2));
    await sync.syncAll(run);
    expect(calls, hasLength(2));
    expect(store.del['b']!.hash, reg(2).hash);
  });

  test('an offline host stays pending and gets it on its next connect', () async {
    await sync.activate(reg(1));
    failWith = {'b': const ConnectionFailure()};
    final out = await sync.syncAll(run);
    expect(out['b'], WebPushHostResult.failed);
    expect(store.del.containsKey('b'), isFalse);
    failWith = {};
    final host = (await hosts.byId('b'))!;
    final res = await sync.syncHost(host, (c, {stdin}) => run('b', c, stdin: stdin));
    expect(res, WebPushHostResult.delivered);
  });

  test('an older hook is marked too old without crashing; retried later', () async {
    await sync.activate(reg(1));
    failWith = {'a': const HookFailure('protocol', 'openmosh-hook returned unexpected output.')};
    final out = await sync.syncAll(run);
    expect(out['a'], WebPushHostResult.hookTooOld);
    expect(out['b'], WebPushHostResult.delivered);
    expect(store.del['a']!.status, WebPushDeliveryStatus.hookTooOld);
    failWith = {};
    expect((await sync.syncAll(run))['a'], WebPushHostResult.delivered);
  });

  test('a rejected registration is a failure, not "too old"', () async {
    await sync.activate(reg(1));
    failWith = {'a': const HookFailure('webpush_invalid', 'bad')};
    expect((await sync.syncAll(run))['a'], WebPushHostResult.failed);
    expect(store.del.containsKey('a'), isFalse);
  });

  test('turn off clears local state and runs clear-webpush; offline hosts owe it', () async {
    await sync.activate(reg(1));
    await sync.syncAll(run);
    calls.clear();
    failWith = {'b': const ConnectionFailure()};
    final out = await sync.disable(run);
    expect(store.reg, isNull);
    expect(out['a'], WebPushHostResult.cleared);
    expect(out['b'], WebPushHostResult.failed);
    expect(calls.first.$2, ['devices', 'clear-webpush', 'da', '--json']);
    expect(store.del.keys, ['b']);
    expect(store.del['b']!.status, WebPushDeliveryStatus.clearPending);
    failWith = {};
    final host = (await hosts.byId('b'))!;
    expect(
      await sync.syncHost(host, (c, {stdin}) => run('b', c, stdin: stdin)),
      WebPushHostResult.cleared,
    );
    expect(store.del, isEmpty);
  });

  test('syncHost without a registration or pending removal does nothing', () async {
    final host = (await hosts.byId('a'))!;
    expect(await sync.syncHost(host, (c, {stdin}) => run('a', c)), WebPushHostResult.skipped);
    expect(calls, isEmpty);
  });

  test('set-webpush builds argv and rejects bad ids', () {
    expect(HookCommand.setWebPush('d1').argv, ['devices', 'set-webpush', 'd1', '--json']);
    expect(() => HookCommand.clearWebPush(''), throwsA(isA<ValidationFailure>()));
    final sh = HookCommand.setWebPush('d1').toScript('/h', stdin: utf8.encode('{"v":1}'));
    expect(sh, contains("printf '%s'"));
    expect(sh, contains("'set-webpush'"));
  });
}
