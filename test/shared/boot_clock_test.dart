import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/monotonic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.openmosh/clock');

  test('reads Android elapsedRealtime, which counts deep sleep', () async {
    var ms = 1000;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'elapsedRealtime' ? ms : null,
    );
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    final clock = bootClock();
    expect(await clock(), const Duration(seconds: 1));
    ms += 3600 * 1000; // an hour asleep
    expect(await clock(), const Duration(seconds: 3601));
  });

  test('falls back to a stopwatch without the platform channel', () async {
    final clock = bootClock();
    final a = await clock();
    final b = await clock();
    expect(b >= a, isTrue);
  });
}
