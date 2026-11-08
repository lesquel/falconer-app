import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/domain/entities/backoff_policy.dart';

void main() {
  test('without jitter the delay doubles from 0.5 s and caps at 8 s', () {
    final p = BackoffPolicy(random: () => 0);
    expect([for (var i = 0; i < 7; i++) p.delay(i).inMilliseconds],
        [500, 1000, 2000, 4000, 8000, 8000, 8000]);
  });

  test('jitter shortens the delay by at most 20 %', () {
    final p = BackoffPolicy(random: () => 0.999999);
    expect(p.delay(0).inMilliseconds, inInclusiveRange(400, 500));
    expect(p.delay(9).inMilliseconds, inInclusiveRange(6400, 8000));
  });

  test('negative attempts are treated as the first one', () {
    expect(BackoffPolicy(random: () => 0).delay(-3).inMilliseconds, 500);
  });
}
