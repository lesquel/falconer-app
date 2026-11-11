import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/herdr/presentation/controllers/herdr_navigator_controller.dart';

import '../../support/herdr_fakes.dart';

HerdrSnapshot withNewTab() {
  final s = sampleSnapshot();
  return HerdrSnapshot(
    workspaces: s.workspaces,
    tabs: [
      ...s.tabs,
      const HerdrTab(id: 'w1:t2', workspaceId: 'w1', label: 'zsh'),
    ],
    panes: [
      ...s.panes,
      const HerdrPane(id: 'w1:p3', tabId: 'w1:t2', workspaceId: 'w1'),
    ],
  );
}

void main() {
  test('run returns the id Herdr gave the new tab', () async {
    final repo = FakeHerdrRepository()..actId = 'w1:t2';
    final c = HerdrNavigatorController(repository: repo, hostId: 'h1');
    addTearDown(c.dispose);
    final r = await c.run(HerdrAction.tabCreate('w1'));
    expect(r.id, 'w1:t2');
    expect(r.failure, isNull);
  });

  test('without an id, the first new tab of the workspace is the one', () async {
    final repo = FakeHerdrRepository();
    final c = HerdrNavigatorController(repository: repo, hostId: 'h1');
    addTearDown(c.dispose);
    c.resume();
    await Future<void>.delayed(Duration.zero);
    final pane = c.paneOfNewTab(workspaceId: 'w1', known: {'w1:t1'});
    repo.changeSnapshot(withNewTab());
    expect((await pane)?.id, 'w1:p3');
  });

  test('gives up after the timeout and when the screen goes away', () async {
    final c = HerdrNavigatorController(repository: FakeHerdrRepository(), hostId: 'h1');
    expect(
      await c.paneOfNewTab(
        workspaceId: 'w1',
        known: {'w1:t1'},
        tabId: 'w1:t9',
        timeout: const Duration(milliseconds: 10),
      ),
      isNull,
    );
    final pending = c.paneOfNewTab(workspaceId: 'w1', known: {'w1:t1'}, tabId: 'w1:t9');
    c.dispose();
    expect(await pending, isNull);
  });
}
