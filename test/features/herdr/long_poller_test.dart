import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/presentation/controllers/long_poller.dart';
import 'package:openmosh/shared/domain/failure.dart';

/// Hands each fetch a completer so the test decides when it answers.
class Calls {
  final List<String?> since = [];
  final List<Completer<Polled<String>>> pending = [];
  int inFlight = 0;
  int maxInFlight = 0;

  Future<Polled<String>> fetch(String? s) {
    since.add(s);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    final c = Completer<Polled<String>>();
    pending.add(c);
    return c.future.whenComplete(() => inFlight--);
  }

  void answer(Polled<String> p) => pending.last.complete(p);
  void fail(Object e) => pending.last.completeError(e);
}

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late Calls calls;
  late List<String> data;
  late List<Object> errors;
  late List<int> backoffs;
  late LongPoller<String> poller;

  setUp(() {
    calls = Calls();
    data = [];
    errors = [];
    backoffs = [];
    poller = LongPoller<String>(
      fetch: calls.fetch,
      onData: (d, _) => data.add(d),
      onError: errors.add,
      backoff: (attempt) {
        backoffs.add(attempt);
        return Duration.zero;
      },
    );
  });

  tearDown(() => poller.dispose());

  test('passes the last rev and keeps it across unchanged answers', () async {
    poller.start();
    await settle();
    expect(calls.since, [null]);
    calls.answer(const Polled('aaaaaaaaaaaaaaaa', false, 'first'));
    await settle();
    expect(data, ['first']);
    expect(calls.since, [null, 'aaaaaaaaaaaaaaaa']);
    calls.answer(const Polled('aaaaaaaaaaaaaaaa', true, null));
    await settle();
    calls.answer(const Polled('bbbbbbbbbbbbbbbb', false, 'second'));
    await settle();
    expect(data, ['first', 'second']);
    expect(calls.since.last, 'bbbbbbbbbbbbbbbb');
  });

  test('never overlaps calls, even when started twice or resumed mid-call', () async {
    poller.start();
    poller.start();
    await settle();
    poller.pause();
    poller.start();
    poller.poke();
    await settle();
    expect(calls.pending.length, 1);
    calls.answer(const Polled('aaaaaaaaaaaaaaaa', false, 'x'));
    await settle();
    expect(calls.maxInFlight, 1);
    expect(calls.pending.length, 2);
  });

  test('stops after the call in flight when paused, and resumes on start', () async {
    poller.start();
    await settle();
    poller.pause();
    calls.answer(const Polled('aaaaaaaaaaaaaaaa', false, 'late'));
    await settle();
    expect(calls.pending.length, 1);
    expect(data, ['late']);
    poller.start();
    await settle();
    expect(calls.pending.length, 2);
    expect(calls.since.last, 'aaaaaaaaaaaaaaaa');
  });

  test('a disposed poller drops the answer and never calls again', () async {
    poller.start();
    await settle();
    poller.dispose();
    calls.answer(const Polled('aaaaaaaaaaaaaaaa', false, 'gone'));
    await settle();
    poller.start();
    await settle();
    expect(data, isEmpty);
    expect(calls.pending.length, 1);
  });

  test('backs off after errors and resets after a success', () async {
    poller.start();
    await settle();
    calls.fail(const HookFailure('runtime_unavailable', 'x'));
    await settle();
    await settle();
    calls.fail(const HookFailure('runtime_unavailable', 'x'));
    await settle();
    await settle();
    expect(backoffs, [0, 1]);
    expect(errors.length, 2);
    calls.answer(const Polled('aaaaaaaaaaaaaaaa', false, 'ok'));
    await settle();
    calls.fail(const HookFailure('runtime_unavailable', 'x'));
    await settle();
    expect(backoffs, [0, 1, 0]);
  });

  test('stops on errors that need the user (cancelled unlock, missing hook)', () async {
    poller.start();
    await settle();
    calls.fail(const UserCancelledFailure());
    await settle();
    await settle();
    expect(errors.single, isA<UserCancelledFailure>());
    expect(calls.pending.length, 1);
    expect(poller.running, isFalse);
  });

  test('poke wakes a backoff sleep at once', () async {
    final slow = LongPoller<String>(
      fetch: calls.fetch,
      onData: (d, _) => data.add(d),
      onError: errors.add,
      backoff: (_) => const Duration(hours: 1),
    );
    addTearDown(slow.dispose);
    slow.start();
    await settle();
    calls.fail(const HookFailure('runtime_unavailable', 'x'));
    await settle();
    expect(calls.pending.length, 1);
    slow.poke();
    await settle();
    await settle();
    expect(calls.pending.length, 2);
  });
}
