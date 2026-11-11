import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/agent_view/domain/entities/screen_block.dart';
import 'package:openmosh/features/agent_view/domain/usecases/parse_agent_screen.dart';

List<String> conversation(String folder) =>
    File('test/features/agent_view/fixtures/$folder/conversation.txt').readAsLinesSync();

const user = TextRole.user;
const agent = TextRole.agent;
const tool = TextRole.tool;

void main() {
  test('TextBlock defaults to the agent role and compares the role', () {
    expect(const TextBlock('a').role, agent);
    expect(const TextBlock('a'), isNot(const TextBlock('a', role: user)));
    expect(const TextBlock('a', role: tool), const TextBlock('a', role: tool));
  });

  test('claude: past prompts are user, Bash calls are tool, replies are agent', () {
    expect(parseAgentScreen('claude', conversation('claude')), const [
      TextBlock('why does the cart total ignore quantities?', role: user),
      TextBlock(
        '● The total sums item prices without multiplying by the quantity.\n'
        '  I will fix src/cart.ts.',
      ),
      // Indented quote inside a reply is not a prompt.
      TextBlock('> note: quantities default to 1'),
      TextBlock(
        '● Bash(npm test -- cart)\n  ⎿  PASS src/cart.test.ts\n     Tests: 4 passed',
        role: tool,
      ),
      TextBlock('also update the changelog\nand the readme', role: user),
      TextBlock('● Done. The changelog has a new entry.'),
    ]);
  });

  test('codex: › turns are user, Ran/Edited cells are tool', () {
    expect(parseAgentScreen('codex', conversation('codex')), const [
      TextBlock('why does the cart total ignore quantities?', role: user),
      TextBlock('• The total sums item prices without the quantity.'),
      TextBlock(
        '• Ran npm test -- cart\n  └ PASS src/cart.test.ts\n    Tests: 4 passed',
        role: tool,
      ),
      TextBlock('• Edited src/cart.ts (+1 -1)', role: tool),
      TextBlock('also update the changelog\nand the readme', role: user),
      TextBlock('• Done.'),
    ]);
  });

  test('pi: tool headers are tool; prompts have no text marker and stay agent', () {
    expect(parseAgentScreen('pi', conversation('pi')), const [
      TextBlock('why does the cart total ignore quantities?'),
      TextBlock('The total sums item prices without the quantity.'),
      TextBlock('\$ npm test -- cart\nPASS src/cart.test.ts', role: tool),
      TextBlock('read src/cart.ts', role: tool),
      TextBlock('read the docs before you change the reducer.'),
    ]);
  });

  test('kiro: echoed > prompts are user, the live prompt stays the input', () {
    expect(parseAgentScreen('kiro', conversation('kiro')), const [
      TextBlock('why does the cart total ignore quantities?', role: user),
      TextBlock('The total sums item prices without the quantity.'),
      TextBlock('fix it', role: user),
      TextBlock('I updated src/cart.ts.'),
      InputBlock(''),
    ]);
  });

  test('aider: echoed > prompts are user', () {
    expect(parseAgentScreen('aider', conversation('aider')), const [
      TextBlock('add type hints to the cart functions', role: user),
      TextBlock('Applied edit to src/cart.py\nCommit 1a2b3c4 feat: add type hints'),
      InputBlock(''),
    ]);
  });

  test('gemini: > turns are user, boxed tool rows are tool', () {
    expect(parseAgentScreen('gemini', conversation('gemini')), const [
      TextBlock('why does the cart total ignore quantities?', role: user),
      TextBlock('✦ The total sums item prices without the quantity.'),
      TextBlock('✔  ReadFile src/cart.ts', role: tool),
      TextBlock('✦ I will fix it now.'),
    ]);
  });

  test('opencode: messages behind the ┃ bar are user', () {
    expect(parseAgentScreen('opencode', conversation('opencode')), const [
      TextBlock('why does the cart total ignore quantities?', role: user),
      TextBlock('The total sums item prices without the quantity.'),
    ]);
  });

  test('plain shell: commands after a prompt are user, their output is tool', () {
    expect(parseAgentScreen(null, conversation('shell')), const [
      TextBlock('ls', role: user),
      TextBlock('package.json  src  test', role: tool),
      TextBlock('npm test', role: user),
      TextBlock('> shop@1.0.0 test\n> node --test', role: tool),
      TextBlock('ok 4 tests', role: tool),
    ]);
  });

  test('plain shell: output before any prompt and bare prompts stay agent', () {
    expect(parseAgentScreen(null, ['welcome to the box', '', r'$ ']), const [
      TextBlock('welcome to the box'),
    ]);
  });

  test('unknown agents never guess a role', () {
    final blocks = parseAgentScreen('somebot', conversation('shell'));
    expect(blocks.whereType<TextBlock>().every((b) => b.role == agent), isTrue, reason: '$blocks');
    final claude = parseAgentScreen('somebot', conversation('claude'));
    expect(claude.whereType<TextBlock>().every((b) => b.role == agent), isTrue);
  });
}
