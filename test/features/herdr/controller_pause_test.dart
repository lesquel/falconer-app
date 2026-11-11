import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/agent_view/presentation/controllers/agent_view_controller.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/features/herdr/presentation/controllers/herdr_navigator_controller.dart';

import '../../support/herdr_fakes.dart';

void main() {
  test('an action that ends after the navigator was hidden does not resume polling', () async {
    final c = HerdrNavigatorController(repository: FakeHerdrRepository(), hostId: 'h1');
    addTearDown(c.dispose);
    c.resume();
    await Future<void>.delayed(Duration.zero);
    c.pause();
    await c.act(HerdrAction.workspaceCreate('x'));
    expect(c.polling, isFalse);
    c.resume();
    expect(c.polling, isTrue);
  });

  test('an action that ends after the agent view was hidden does not resume polling', () async {
    final c = AgentViewController(repository: FakeHerdrRepository(), hostId: 'h1', paneId: 'w1:p1');
    addTearDown(c.dispose);
    c.resume();
    await Future<void>.delayed(Duration.zero);
    c.pause();
    await c.sendKeys(const ['enter']);
    expect(c.polling, isFalse);
  });
}
