import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/agent_view/domain/entities/screen_block.dart';
import 'package:openmosh/features/agent_view/domain/usecases/parse_agent_screen.dart';

const _fixtures = 'test/features/agent_view/fixtures';

List<String> fixture(String agent, String name) =>
    File('$_fixtures/$agent/$name.txt').readAsLinesSync();

List<ScreenBlock> parse(String? agent, String folder, String name) =>
    parseAgentScreen(agent, fixture(folder, name));

List<ScreenBlock> parseFixture(String agent, String name) => parse(agent, agent, name);

ChoiceOption opt(String label, List<String> keys, ChoiceKind kind, {bool selected = false}) =>
    ChoiceOption(label, keys, selected, kind);

const allow = ChoiceKind.allow;
const always = ChoiceKind.allowAlways;
const deny = ChoiceKind.deny;
const other = ChoiceKind.other;

void expectOnlyText(List<ScreenBlock> blocks) {
  expect(blocks, isNotEmpty);
  expect(blocks.every((b) => b is TextBlock), isTrue, reason: '$blocks');
}

void expectNoChoice(List<ScreenBlock> blocks) {
  expect(blocks.whereType<ChoiceBlock>(), isEmpty, reason: '$blocks');
}

String allText(List<ScreenBlock> blocks) =>
    blocks.whereType<TextBlock>().map((b) => b.text).join('\n');

void main() {
  group('claude', () {
    test('permission menu becomes a ChoiceBlock with digit keys', () {
      expect(parseFixture('claude', 'permission'), const [
        TextBlock("⏺ I'll install the dependencies first."),
        TextBlock('⏺ Bash(npm install)\n  ⎿  Running…'),
        TextBlock('Bash command'),
        TextBlock('npm install\nInstall project dependencies'),
        ChoiceBlock('Do you want to proceed?', [
          ChoiceOption('Yes', ['1'], true, allow),
          ChoiceOption(
            "Yes, and don't ask again for npm install commands in /home/dev/projects/shop",
            ['2'],
            false,
            always,
          ),
          ChoiceOption('No, and tell Claude what to do differently', ['3'], false, deny),
        ]),
      ]);
    });

    test('boxed edit prompt keeps the moved cursor and strips nested borders', () {
      expect(parseFixture('claude', 'permission_edit_boxed'), const [
        TextBlock('⏺ Update(src/cart.ts)'),
        TextBlock('Edit file'),
        TextBlock('src/cart.ts'),
        TextBlock(
          '12  -  return items.reduce((a, b) => a + b.price, 0);\n'
          '12  +  return items.reduce((a, b) => a + b.price * b.qty, 0);',
        ),
        ChoiceBlock('Do you want to make this edit to cart.ts?', [
          ChoiceOption('Yes', ['1'], false, allow),
          ChoiceOption('Yes, allow all edits during this session', ['2'], true, always),
          ChoiceOption('No, and tell Claude what to do differently', ['3'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text, without borders or status noise', () {
      expect(parseFixture('claude', 'plain'), const [
        TextBlock('✻ Welcome to Claude Code!'),
        TextBlock('/help for help, /status for your current setup'),
        TextBlock('cwd: /home/dev/projects/shop'),
        TextBlock('> what does this repo do?'),
        TextBlock(
          '⏺ This repository is a small online shop built with Express.\n'
          '  The main entry point is src/server.ts and routes live in\n'
          '  src/routes/.',
        ),
      ]);
    });

    test('input box becomes an InputBlock with the multi-line draft', () {
      expect(parseFixture('claude', 'input'), const [
        TextBlock('⏺ Done. All 42 tests pass.'),
        InputBlock('add a README section about deployment\nand mention the env vars'),
      ]);
    });

    test('numbered plan in normal output is never a ChoiceBlock', () {
      final blocks = parseFixture('claude', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
      expect(allText(blocks), contains('1. Install deps'));
    });
  });

  group('codex', () {
    test('approval prompt becomes a ChoiceBlock', () {
      expect(parseFixture('codex', 'permission'), const [
        TextBlock('• I need to install dependencies before running the tests.'),
        TextBlock('• Running npm install'),
        TextBlock('Reason: npm install needs network access to fetch packages'),
        TextBlock(r'$ npm install'),
        ChoiceBlock('Would you like to run the following command?', [
          ChoiceOption('Yes, just this once', ['1'], true, allow),
          ChoiceOption(
            "Yes, and don't ask again for this command in this session",
            ['2'],
            false,
            always,
          ),
          ChoiceOption('No, and tell Codex what to do differently', ['3'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text', () {
      final blocks = parseFixture('codex', 'plain');
      expectOnlyText(blocks);
      expect(allText(blocks), isNot(contains('esc to interrupt')));
      expect(allText(blocks), contains('Quantities are ignored'));
    });

    test('composer becomes an InputBlock', () {
      expect(parseFixture('codex', 'input'), const [
        TextBlock('• All tests passed.'),
        InputBlock('refactor the cart module to use a reducer\nand keep the public API'),
      ]);
    });

    test('numbered plan is not a menu and the placeholder is an empty draft', () {
      final blocks = parseFixture('codex', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('pi', () {
    test('confirm dialog becomes a ChoiceBlock with arrow keys', () {
      expect(parseFixture('pi', 'permission'), const [
        TextBlock('Running bash\n\$ rm -rf build/'),
        ChoiceBlock('Dangerous command\nrm -rf build/', [
          ChoiceOption('Yes', ['enter'], true, allow),
          ChoiceOption('No', ['down', 'enter'], false, deny),
        ]),
      ]);
    });

    test('select list keys move from the current selection', () {
      expect(parseFixture('pi', 'select'), const [
        TextBlock('Which database should I use?'),
        ChoiceBlock('Pick a database', [
          ChoiceOption('SQLite', ['up', 'up', 'enter'], false, other),
          ChoiceOption('Postgres', ['up', 'enter'], false, other),
          ChoiceOption('MySQL', ['enter'], true, other),
        ]),
      ]);
    });

    test('plain output is only text', () {
      expect(parseFixture('pi', 'plain'), const [
        TextBlock('read src/cart.ts'),
        TextBlock(
          'The cart total is computed in src/cart.ts by summing item prices.\n'
          'Quantities are ignored, which is the bug you reported.',
        ),
        TextBlock('I will fix it by multiplying price by quantity.'),
      ]);
    });

    test('editor between rules becomes an InputBlock and the footer is dropped', () {
      expect(parseFixture('pi', 'input'), const [
        TextBlock('Here is the summary of the changes.'),
        InputBlock('add tests for the cart reducer'),
      ]);
    });

    test('arrow list without the selector frame is not a menu', () {
      final blocks = parseFixture('pi', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
      expect(allText(blocks), contains('→ Option A: keep the old API'));
    });
  });

  group('gemini', () {
    test('confirmation becomes a ChoiceBlock', () {
      expect(parseFixture('gemini', 'permission'), const [
        TextBlock('✦ I will install the dependencies.'),
        TextBlock('?  Shell npm install [current working directory /home/dev/shop]'),
        TextBlock('npm install'),
        ChoiceBlock("Allow execution of: 'npm'?", [
          ChoiceOption('Yes, allow once', ['1'], true, allow),
          ChoiceOption('Yes, allow always ...', ['2'], false, always),
          ChoiceOption('No, suggest changes', ['3'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text', () {
      final blocks = parseFixture('gemini', 'plain');
      expectOnlyText(blocks);
      expect(allText(blocks), contains('ReadFile src/cart.ts'));
    });

    test('input box becomes an InputBlock', () {
      expect(parseFixture('gemini', 'input'), const [
        TextBlock('✦ Done.'),
        InputBlock('write a unit test for utils.ts'),
      ]);
    });

    test('numbered plan is not a menu', () {
      final blocks = parseFixture('gemini', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('kiro', () {
    test('[y/n/t] prompt becomes a yes/no ChoiceBlock', () {
      final blocks = parseFixture('kiro', 'permission');
      expect(
        blocks.last,
        const ChoiceBlock('Allow this action?', [
          ChoiceOption('Yes', ['y', 'enter'], false, allow),
          ChoiceOption('No', ['n', 'enter'], false, deny),
        ]),
      );
      expect(blocks.whereType<ChoiceBlock>(), hasLength(1));
      expect(blocks.whereType<InputBlock>(), isEmpty);
      expect(allText(blocks), contains('npm install'));
    });

    test('plain output is only text', () {
      expectOnlyText(parseFixture('kiro', 'plain'));
    });

    test('prompt line becomes an InputBlock', () {
      expect(parseFixture('kiro', 'input'), const [
        TextBlock('The fix is in place and the tests pass.'),
        InputBlock('fix the failing lint warnings'),
      ]);
    });

    test('free-form yes/no question is not a menu', () {
      final blocks = parseFixture('kiro', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('opencode', () {
    test('permission dialog becomes a ChoiceBlock', () {
      expect(parseFixture('opencode', 'permission'), const [
        TextBlock('install the dependencies'),
        TextBlock("I'll install the project dependencies."),
        TextBlock(r'$ Install project dependencies'),
        TextBlock('npm install'),
        ChoiceBlock('Permission required', [
          ChoiceOption('Allow once', ['enter'], true, allow),
          ChoiceOption('Allow always', ['right', 'enter'], false, always),
          ChoiceOption('Reject', ['esc'], false, deny),
        ]),
      ]);
    });

    test('plain output with a user message bar is only text', () {
      final blocks = parseFixture('opencode', 'plain');
      expectOnlyText(blocks);
      expect(allText(blocks), contains('where is the cart total computed?'));
    });

    test('prompt box becomes an InputBlock without the model line', () {
      expect(parseFixture('opencode', 'input'), const [
        TextBlock('The cart total is computed in src/cart.ts.'),
        InputBlock('explain the checkout flow'),
      ]);
    });

    test('numbered plan is not a menu', () {
      final blocks = parseFixture('opencode', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('copilot', () {
    test('permission menu becomes a ChoiceBlock', () {
      expect(parseFixture('copilot', 'permission'), const [
        TextBlock('● Run npm install to install dependencies\n  \$ npm install'),
        TextBlock('Run command'),
        TextBlock('npm install'),
        ChoiceBlock('Do you want to run this command?', [
          ChoiceOption('Yes', ['1'], true, allow),
          ChoiceOption(
            'Yes, and approve `npm` for the rest of the running session',
            ['2'],
            false,
            always,
          ),
          ChoiceOption('No, and tell Copilot what to do differently', ['3'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text', () {
      expectOnlyText(parseFixture('copilot', 'plain'));
    });

    test('input box becomes an InputBlock', () {
      expect(parseFixture('copilot', 'input'), const [
        TextBlock('● Done.'),
        InputBlock('list the open issues'),
      ]);
    });

    test('numbered plan is not a menu', () {
      final blocks = parseFixture('copilot', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('cursor', () {
    test('approval box becomes a ChoiceBlock with arrow keys', () {
      expect(parseFixture('cursor', 'permission'), const [
        TextBlock('⬢ Read src/cart.ts'),
        TextBlock('Not in allowlist: npm install'),
        ChoiceBlock('Run this command?', [
          ChoiceOption('Run (once)', ['enter'], true, allow),
          ChoiceOption('Add Shell(npm) to allowlist?', ['down', 'enter'], false, always),
          ChoiceOption('Skip', ['down', 'down', 'enter'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text', () {
      expectOnlyText(parseFixture('cursor', 'plain'));
    });

    test('input box becomes an InputBlock', () {
      expect(parseFixture('cursor', 'input'), const [
        TextBlock('Done.'),
        InputBlock('refactor the cart module'),
      ]);
    });

    test('arrow list in normal output is not a menu', () {
      final blocks = parseFixture('cursor', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('amp', () {
    test('approval box becomes a ChoiceBlock', () {
      expect(parseFixture('amp', 'permission'), const [
        TextBlock("I'll install the dependencies."),
        TextBlock(r'$ npm install'),
        ChoiceBlock('Allow running this command?', [
          ChoiceOption('Allow', ['enter'], true, allow),
          ChoiceOption('Allow all for this session', ['down', 'enter'], false, always),
          ChoiceOption('Deny', ['down', 'down', 'enter'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text', () {
      expectOnlyText(parseFixture('amp', 'plain'));
    });

    test('input box becomes an InputBlock', () {
      expect(parseFixture('amp', 'input'), const [
        TextBlock('Done.'),
        InputBlock('summarize the open TODOs'),
      ]);
    });

    test('numbered plan is not a menu', () {
      final blocks = parseFixture('amp', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('aider', () {
    test('(Y)es/(N)o prompt becomes a ChoiceBlock with the default selected', () {
      expect(parseFixture('aider', 'permission'), const [
        TextBlock('To install the dependencies run:'),
        TextBlock('npm install'),
        ChoiceBlock('Run shell command?', [
          ChoiceOption('Yes', ['y', 'enter'], true, allow),
          ChoiceOption('No', ['n', 'enter'], false, deny),
        ]),
      ]);
    });

    test('plain output is only text', () {
      expectOnlyText(parseFixture('aider', 'plain'));
    });

    test('prompt line becomes an InputBlock', () {
      expect(parseFixture('aider', 'input'), const [
        TextBlock('Added src/cart.py to the chat'),
        TextBlock('src/cart.py'),
        InputBlock('add type hints to the cart functions'),
      ]);
    });

    test('numbered plan is not a menu', () {
      final blocks = parseFixture('aider', 'ambiguous');
      expectNoChoice(blocks);
      expect(blocks.last, const InputBlock(''));
    });
  });

  group('unknown agent (generic conservative detector)', () {
    test('framed numbered menu with a cursor, question and key hint is a ChoiceBlock', () {
      final blocks = parse(null, 'claude', 'permission');
      final choice = blocks.whereType<ChoiceBlock>().single;
      expect(choice.question, 'Do you want to proceed?');
      expect(choice.options.map((o) => o.keys), [
        ['1'],
        ['2'],
        ['3'],
      ]);
    });

    test('numbered menu without a key hint stays text', () {
      expectOnlyText(parse(null, 'generic', 'numbered_without_hint'));
    });

    test('an unrecognized agent id falls back to the generic detector', () {
      expectOnlyText(parse('some-new-agent', 'generic', 'numbered_without_hint'));
      expect(
        parse('Claude', 'generic', 'numbered_without_hint').whereType<ChoiceBlock>(),
        hasLength(1),
      );
    });

    test('numbered plan is not a menu', () {
      expectNoChoice(parse(null, 'claude', 'ambiguous'));
    });

    test('framed input line becomes an InputBlock', () {
      expect(parse(null, 'claude', 'input').last, isA<InputBlock>());
    });
  });

  group('robustness', () {
    test('empty screen gives no blocks', () {
      expect(parseAgentScreen('claude', const []), isEmpty);
      expect(parseAgentScreen(null, const ['', '   ', '────']), isEmpty);
    });

    test('menus needing more than 8 keys stay text', () {
      final lines = [
        ' Pick a model',
        '',
        for (var i = 0; i < 10; i++) i == 9 ? ' → model-$i' : '   model-$i',
        '',
        ' ↑↓ navigate  enter select  esc cancel',
      ];
      expectNoChoice(parseAgentScreen('pi', lines));
    });

    test('a single option is never a menu', () {
      final lines = ['Do you want to proceed?', '❯ 1. Yes', '', 'Esc to cancel'];
      expectNoChoice(parseAgentScreen('claude', lines));
    });

    test('two cursors are never a menu', () {
      final lines = ['Do you want to proceed?', '❯ 1. Yes', '❯ 2. No', '', 'Esc to cancel'];
      expectNoChoice(parseAgentScreen('claude', lines));
    });

    test('a menu far above the bottom of the screen is stale and stays text', () {
      final lines = [
        ...fixture('claude', 'permission'),
        for (var i = 0; i < 12; i++) '⏺ later output line $i',
      ];
      expectNoChoice(parseAgentScreen('claude', lines));
    });

    test('400 lines parse in well under 5 ms, even with pathological lines', () {
      final screen = [
        for (var i = 0; i < 8; i++) ...fixture('claude', 'plain'),
        '${' ' * 3000}1.${' ' * 3000}x',
        '│${'─' * 3000}${' ' * 3000}│',
        '${'❯ ' * 1500}1. y',
        for (var i = 0; i < 400; i++) '  $i. ${'word ' * 20}',
        ...fixture('claude', 'permission'),
      ].sublist(0, 400);
      for (final agent in [null, 'claude', 'codex', 'pi', 'gemini', 'kiro', 'opencode']) {
        parseAgentScreen(agent, screen);
      }
      final watch = Stopwatch()..start();
      const runs = 20;
      for (var i = 0; i < runs; i++) {
        for (final agent in ['claude', 'codex', 'pi', 'opencode', 'aider', null]) {
          parseAgentScreen(agent, screen);
        }
      }
      final perParseMs = watch.elapsedMicroseconds / (runs * 6) / 1000;
      expect(perParseMs, lessThan(5), reason: '$perParseMs ms per parse');
    });
  });
}
