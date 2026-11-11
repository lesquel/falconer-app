import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_action.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';

Map<String, Object?> body(HerdrAction a) =>
    jsonDecode(utf8.decode(a.toBytes())) as Map<String, Object?>;

void main() {
  group('herdr hook commands', () {
    test('version asks for JSON', () {
      expect(HookCommand.version().argv, ['version', '--json']);
    });

    test('snapshot without polling', () {
      expect(HookCommand.herdrSnapshot().argv, ['herdr', 'snapshot', '--json']);
    });

    test('snapshot long-poll passes session, since and wait', () {
      expect(
        HookCommand.herdrSnapshot(
          session: 'default',
          since: '0123456789abcdef',
          waitMs: 15000,
        ).argv,
        [
          'herdr',
          'snapshot',
          '--session',
          'default',
          '--since',
          '0123456789abcdef',
          '--wait-ms',
          '15000',
          '--json',
        ],
      );
    });

    test('read quotes the pane id as one word', () {
      final cmd = HookCommand.herdrRead('w1:p2', session: 'omtest-1', lines: 120);
      expect(cmd.argv, [
        'herdr',
        'read',
        '--pane',
        'w1:p2',
        '--session',
        'omtest-1',
        '--lines',
        '120',
        '--json',
      ]);
      expect(
        cmd.toShell('/h'),
        "'/h' 'herdr' 'read' '--pane' 'w1:p2' '--session' 'omtest-1' '--lines' '120' '--json'",
      );
    });

    test('action body goes on stdin through printf', () {
      final cmd = HookCommand.herdrAction(session: 'default');
      expect(cmd.argv, ['herdr', 'action', '--session', 'default', '--json']);
      final script = cmd.toScript('/h', stdin: HerdrAction.paneFocus('w1:p2').toBytes());
      expect(
        script,
        "printf '%s' '{\"op\":\"pane.focus\",\"id\":\"w1:p2\"}' | "
        "'/h' 'herdr' 'action' '--session' 'default' '--json'\n",
      );
    });

    test('rejects bad pane ids, sessions, revisions and ranges', () {
      for (final bad in ['', '-x', 'a b', "a'b", 'a\nb', 'x' * 65]) {
        expect(() => HookCommand.herdrRead(bad), throwsA(isA<ValidationFailure>()), reason: bad);
      }
      for (final bad in ['-s', 'a/b', '..', 'a b', 'x' * 65]) {
        expect(
          () => HookCommand.herdrSnapshot(session: bad),
          throwsA(isA<ValidationFailure>()),
          reason: bad,
        );
      }
      expect(() => HookCommand.herdrSnapshot(since: 'xyz'), throwsA(isA<ValidationFailure>()));
      expect(() => HookCommand.herdrSnapshot(waitMs: 20001), throwsA(isA<ValidationFailure>()));
      expect(() => HookCommand.herdrRead('w1:p1', lines: 0), throwsA(isA<ValidationFailure>()));
      expect(() => HookCommand.herdrRead('w1:p1', lines: 2001), throwsA(isA<ValidationFailure>()));
      // The hook reads up to 2000 lines of history.
      expect(HookCommand.herdrRead('w1:p1', lines: 2000).argv, contains('2000'));
    });
  });

  group('herdr actions', () {
    test('workspace and tab operations', () {
      expect(body(HerdrAction.workspaceCreate()), {'op': 'workspace.create'});
      expect(body(HerdrAction.workspaceCreate('api')), {'op': 'workspace.create', 'label': 'api'});
      expect(body(HerdrAction.workspaceRename('w1', ' web ')), {
        'op': 'workspace.rename',
        'id': 'w1',
        'label': 'web',
      });
      expect(body(HerdrAction.workspaceClose('w1')), {'op': 'workspace.close', 'id': 'w1'});
      expect(body(HerdrAction.tabCreate('w1', 'logs')), {
        'op': 'tab.create',
        'workspace_id': 'w1',
        'label': 'logs',
      });
      expect(body(HerdrAction.tabRename('w1:t2', 'b')), {
        'op': 'tab.rename',
        'id': 'w1:t2',
        'label': 'b',
      });
      expect(body(HerdrAction.tabClose('w1:t2')), {'op': 'tab.close', 'id': 'w1:t2'});
    });

    test('pane operations', () {
      expect(body(HerdrAction.agentStart('w1:p1', 'claude')), {
        'op': 'agent.start',
        'pane_id': 'w1:p1',
        'agent': 'claude',
      });
      expect(body(HerdrAction.paneKeys('w1:p1', ['down', 'enter'])), {
        'op': 'pane.keys',
        'pane_id': 'w1:p1',
        'keys': ['down', 'enter'],
      });
      expect(body(HerdrAction.paneText('w1:p1', 'run the tests')), {
        'op': 'pane.text',
        'pane_id': 'w1:p1',
        'text': 'run the tests',
        'submit': true,
      });
    });

    test('labels are 1-64 characters without control characters', () {
      expect(() => HerdrAction.workspaceRename('w1', '  '), throwsA(isA<ValidationFailure>()));
      expect(() => HerdrAction.tabRename('w1:t1', 'x' * 65), throwsA(isA<ValidationFailure>()));
      expect(body(HerdrAction.tabRename('w1:t1', 'a\u0007b'))['label'], 'ab');
    });

    test('only allowlisted keys, agents and bounded text', () {
      expect(() => HerdrAction.paneKeys('w1:p1', ['f1']), throwsA(isA<ValidationFailure>()));
      expect(() => HerdrAction.paneKeys('w1:p1', []), throwsA(isA<ValidationFailure>()));
      expect(
        () => HerdrAction.paneKeys('w1:p1', List.filled(9, 'up')),
        throwsA(isA<ValidationFailure>()),
      );
      expect(() => HerdrAction.agentStart('w1:p1', 'aider'), throwsA(isA<ValidationFailure>()));
      expect(() => HerdrAction.paneText('w1:p1', '  '), throwsA(isA<ValidationFailure>()));
      expect(() => HerdrAction.paneText('w1:p1', 'x' * 4001), throwsA(isA<ValidationFailure>()));
      expect(() => HerdrAction.workspaceClose('a b'), throwsA(isA<ValidationFailure>()));
      expect(startableAgents, [
        'claude',
        'codex',
        'gemini',
        'cursor',
        'copilot',
        'kiro',
        'opencode',
        'amp',
        'pi',
      ]);
    });
  });
}
