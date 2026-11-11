import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/di.dart';
import 'package:openmosh/features/hosts/presentation/controllers/host_detail_controller.dart';

import '../../support/herdr_fakes.dart';

void main() {
  ProviderContainer container(FakeHerdrRepository repo) {
    final c = ProviderContainer(overrides: [herdrRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(c.dispose);
    // Keep the auto-dispose controller alive for the test.
    c.listen(hostDetailProvider('h1'), (_, _) {});
    return c;
  }

  test('checking Herdr support works before the sessions are loaded', () async {
    final c = container(FakeHerdrRepository());
    expect(await c.read(hostDetailProvider('h1').notifier).checkHerdr(), isTrue);
    expect(c.read(hostDetailProvider('h1')).herdr, isTrue);
    expect(c.read(hostDetailProvider('h1')).sessions, isNull);
  });

  test('an outdated hook answers no', () async {
    final c = container(FakeHerdrRepository()..supported = false);
    expect(await c.read(hostDetailProvider('h1').notifier).checkHerdr(), isFalse);
    expect(c.read(hostDetailProvider('h1')).herdr, isFalse);
  });
}
