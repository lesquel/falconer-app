import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/agent_view/domain/entities/agent_entry.dart';
import 'package:openmosh/features/agent_view/domain/entities/screen_block.dart';
import 'package:openmosh/features/agent_view/domain/usecases/agent_entries.dart';
import 'package:openmosh/features/agent_view/domain/usecases/parse_agent_screen.dart';

AgentEntry tool(String text) => entryFor(TextBlock(text, role: TextRole.tool));
AgentEntry agent(String text) => entryFor(TextBlock(text));

List<AgentEntry> conversation(String id) => [
  for (final b in parseAgentScreen(
    id,
    File('test/features/agent_view/fixtures/$id/conversation.txt').readAsLinesSync(),
  ).whereType<TextBlock>())
    entryFor(b),
];

void main() {
  group('commands', () {
    test('claude Bash call keeps the command and its output', () {
      final e = tool('● Bash(npm test -- cart)\n  ⎿  PASS src/cart.test.ts\n     Tests: 4 passed');
      expect(e, isA<CommandEntry>());
      e as CommandEntry;
      expect(e.command, 'npm test -- cart');
      expect(e.output, ['PASS src/cart.test.ts', 'Tests: 4 passed']);
      expect(e.state, CommandState.unknown);
    });

    test('codex Ran cell', () {
      final e = tool('• Ran npm test -- cart\n  └ PASS src/cart.test.ts\n    Tests: 4 passed');
      expect((e as CommandEntry).command, 'npm test -- cart');
      expect(e.output, ['PASS src/cart.test.ts', 'Tests: 4 passed']);
    });

    test('codex Running cell is in progress', () {
      expect((tool('• Running npm test') as CommandEntry).state, CommandState.running);
    });

    test('pi dollar header', () {
      final e = tool('\$ npm test -- cart\nPASS src/cart.test.ts');
      expect((e as CommandEntry).command, 'npm test -- cart');
      expect(e.output, ['PASS src/cart.test.ts']);
    });

    test('gemini shell row reports the state its glyph shows', () {
      expect((tool('✔  Shell npm test') as CommandEntry).state, CommandState.succeeded);
      expect((tool('✕  Shell npm test') as CommandEntry).state, CommandState.failed);
    });

    test('a non-zero exit code is a failure; success is never guessed', () {
      expect(
        (tool('● Bash(false)\n  ⎿  Error: Exit code 1') as CommandEntry).state,
        CommandState.failed,
      );
      expect((tool('● Bash(true)\n  ⎿  ok') as CommandEntry).state, CommandState.unknown);
    });
  });

  group('file edits', () {
    test('claude Update counts the diff rows', () {
      final e = tool(
        '● Update(src/cart.ts)\n'
        '  ⎿  Updated src/cart.ts with 1 addition and 1 removal\n'
        '      12 -  return price;\n'
        '      12 +  return price * qty;',
      );
      expect(e, isA<EditEntry>());
      e as EditEntry;
      expect(e.path, 'src/cart.ts');
      expect((e.added, e.removed), (1, 1));
      expect(e.diff.map((r) => r.kind), [DiffKind.removed, DiffKind.added]);
      expect(e.diff.last.text, ' return price * qty;');
    });

    test('codex Edited reads the counts from its header', () {
      final e = tool('• Edited src/cart.ts (+3 -1)');
      expect((e as EditEntry).path, 'src/cart.ts');
      expect((e.added, e.removed), (3, 1));
    });

    test('pi edit and gemini WriteFile', () {
      expect((tool('edit src/cart.ts') as EditEntry).path, 'src/cart.ts');
      expect((tool('✔  WriteFile src/cart.ts') as EditEntry).path, 'src/cart.ts');
    });

    test('aider Applied edit', () {
      expect((tool('Applied edit to src/cart.py') as EditEntry).path, 'src/cart.py');
    });
  });

  group('activity', () {
    for (final (text, kind, label) in [
      ('● Read(src/cart.ts)', ActivityKind.read, 'src/cart.ts'),
      ('● Grep(quantity)', ActivityKind.search, 'quantity'),
      ('✔  ReadFile src/cart.ts', ActivityKind.read, 'src/cart.ts'),
      ('read src/cart.ts', ActivityKind.read, 'src/cart.ts'),
      ('ls src', ActivityKind.read, 'src'),
      ('✱ Grep "quantity"', ActivityKind.search, '"quantity"'),
      ('• Explored', ActivityKind.read, 'Explored'),
    ]) {
      test(text, () {
        final e = tool(text);
        expect(e, isA<ActivityEntry>());
        expect((e as ActivityEntry).kind, kind);
        expect(e.label, label);
      });
    }

    test('an unknown tool keeps its whole text', () {
      final e = tool('● mcp__docs__search(query)');
      expect((e as ActivityEntry).kind, ActivityKind.other);
      expect(e.label, contains('mcp__docs__search'));
    });

    test('tool output without a header stays output (a shell)', () {
      final e = tool('package.json  src  test');
      expect(e, isA<OutputEntry>());
      expect((e as OutputEntry).lines, ['package.json  src  test']);
    });
  });

  group('agent messages', () {
    test('the speaker glyph is removed and wrapped lines are joined', () {
      final e = agent('● The total sums item prices\n  without the quantity.');
      expect((e as MessageEntry).segments, [
        const MessageSegment(
          SegmentKind.paragraph,
          'The total sums item prices without the quantity.',
        ),
      ]);
    });

    for (final glyph in ['⏺', '•', '✦']) {
      test('strips $glyph', () {
        expect((agent('$glyph Done.') as MessageEntry).segments.single.text, 'Done.');
      });
    }

    test('bullets and numbered items stay separate', () {
      final e = agent('Plan:\n- first\n- second\n1. third') as MessageEntry;
      expect(e.segments.map((s) => s.kind), [
        SegmentKind.paragraph,
        SegmentKind.bullet,
        SegmentKind.bullet,
        SegmentKind.numbered,
      ]);
      expect(e.segments[1].text, 'first');
      expect(e.segments[3].marker, '1.');
    });

    test('prose ending in a semicolon or with an indent is not code', () {
      final e = agent('Fix the total;\n  then ship it;') as MessageEntry;
      expect(e.segments.single.kind, SegmentKind.paragraph);
    });

    test('tables and trees keep their columns', () {
      final e = agent('src\n├── a.ts\n└── b.ts') as MessageEntry;
      expect(e.segments.single.kind, SegmentKind.preformatted);
      expect(e.segments.single.text, 'src\n├── a.ts\n└── b.ts');
    });

    test('thinking', () {
      expect(agent('✻ Thinking…'), isA<ThinkingEntry>());
      expect(agent('∴ Thought for 3s'), isA<ThinkingEntry>());
    });

    test('errors', () {
      final e = agent('● API Error: 529 overloaded\n  Retry later.');
      expect((e as ErrorEntry).title, 'API Error: 529 overloaded');
      expect(e.detail, 'Retry later.');
    });

    test('a sentence about an error is a message', () {
      expect(agent('The error is in the cart total.'), isA<MessageEntry>());
    });
  });

  test('a user prompt stays exactly as written', () {
    final e = entryFor(const TextBlock('fix it\n  please', role: TextRole.user));
    expect((e as UserEntry).text, 'fix it\n  please');
  });

  group('conversations of every agent with known markers', () {
    test('claude', () {
      final e = conversation('claude');
      expect(e.first, isA<UserEntry>());
      expect(e.whereType<CommandEntry>().single.command, 'npm test -- cart');
    });

    test('codex', () {
      final e = conversation('codex');
      expect(e.whereType<CommandEntry>().single.command, 'npm test -- cart');
      expect(e.whereType<EditEntry>().single.path, 'src/cart.ts');
    });

    test('gemini', () {
      expect(conversation('gemini').whereType<ActivityEntry>().single.label, 'src/cart.ts');
    });

    test('pi', () {
      final e = conversation('pi');
      expect(e.whereType<CommandEntry>().single.command, 'npm test -- cart');
      expect(e.whereType<ActivityEntry>().single.label, 'src/cart.ts');
    });

    test('kiro and opencode tell the user from the agent', () {
      for (final id in ['kiro', 'opencode']) {
        final e = conversation(id);
        expect(e.first, isA<UserEntry>(), reason: id);
        expect(e.whereType<MessageEntry>(), isNotEmpty, reason: id);
      }
    });
  });

  group('new tool markers', () {
    test('aider edits and commits are tool lines', () {
      expect(parseAgentScreen('aider', ['Applied edit to src/cart.py']), const [
        TextBlock('Applied edit to src/cart.py', role: TextRole.tool),
      ]);
      expect(parseAgentScreen('aider', ['Commit 1a2b3c4 fix: cart total']), const [
        TextBlock('Commit 1a2b3c4 fix: cart total', role: TextRole.tool),
      ]);
    });

    test('aider prose that starts alike stays agent text', () {
      expect(parseAgentScreen('aider', ['Commit to the plan before editing.']), const [
        TextBlock('Commit to the plan before editing.'),
      ]);
    });

    test('opencode tool rows are tool lines', () {
      expect(parseAgentScreen('opencode', ['✱ Grep "quantity"']), const [
        TextBlock('✱ Grep "quantity"', role: TextRole.tool),
      ]);
      expect(parseAgentScreen('opencode', ['% WebFetch https://example.com']), const [
        TextBlock('% WebFetch https://example.com', role: TextRole.tool),
      ]);
    });
  });
}
