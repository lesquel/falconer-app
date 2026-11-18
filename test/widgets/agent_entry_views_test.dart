import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/theme.dart';
import 'package:openmosh/features/agent_view/domain/entities/agent_entry.dart';
import 'package:openmosh/features/agent_view/domain/entities/screen_block.dart';
import 'package:openmosh/features/agent_view/presentation/views/agent_entry_views.dart';
import 'package:openmosh/features/agent_view/presentation/views/agent_screen_view.dart';
import 'package:openmosh/features/herdr/domain/entities/herdr_snapshot.dart';
import 'package:openmosh/features/terminal/presentation/views/chat_composer.dart';
import 'package:openmosh/l10n/l10n.dart';

Widget app(Widget child, {Brightness brightness = Brightness.dark}) => MaterialApp(
  theme: buildTheme(brightness),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: supportedAppLocales,
  home: Scaffold(body: child),
);

const everyKind = <ScreenBlock>[
  TextBlock('fix the cart total', role: TextRole.user),
  TextBlock('● The total **ignores** `qty`.\n- first step\n1. second step'),
  TextBlock('● Read(src/cart.ts)', role: TextRole.tool),
  TextBlock(
    '● Bash(npm test -- cart)\n  ⎿  one\n     two\n     three\n     four',
    role: TextRole.tool,
  ),
  TextBlock(
    '● Update(src/a/very/long/path/that/keeps/going/and/going/cart.ts)\n'
    '  ⎿  Updated with 1 addition and 1 removal\n'
    '      12 -  return price;\n'
    '      12 +  return price * qty;',
    role: TextRole.tool,
  ),
  TextBlock('✻ Thinking…'),
  TextBlock('API Error: 529 overloaded\nRetry later.'),
];

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('every kind fits a small phone in ${brightness.name}', (t) async {
      t.view.physicalSize = const Size(320, 1200);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        app(
          AgentScreenView(
            title: 'claude',
            subtitle: 'omtest-shop',
            blocks: everyKind,
            loaded: true,
            onKeys: (_) {},
            onRetry: () {},
            onTerminalMode: () {},
            composer: const SizedBox(height: 44),
          ),
          brightness: brightness,
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Claude Code'), findsOneWidget);
      expect(find.text('omtest-shop'), findsOneWidget);
      expect(find.text('Command'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('+1'), findsOneWidget);
      expect(find.text('−1'), findsOneWidget);
    });
  }

  for (final scale in [1.5, 2.0]) {
    testWidgets('the header fits 320 px at text scale $scale', (t) async {
      t.view.physicalSize = const Size(320, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedAppLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: AgentScreenView(
              title: 'copilot',
              subtitle: 'omtest-a-rather-long-session-name',
              status: HerdrStatus.blocked,
              blocks: const [],
              loaded: true,
              onBack: () {},
              onKeys: (_) {},
              onRetry: () {},
              onTerminalMode: () {},
              composer: const SizedBox(height: 44),
            ),
          ),
        ),
      );
      await t.pump();
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('a failed edit says so and shows why', (t) async {
    await t.pumpWidget(
      app(const AgentEntryView(EditEntry('a.ts', failed: true, notes: ['Permission denied']))),
    );
    expect(find.text('Failed'), findsOneWidget);
    expect(find.text('Permission denied'), findsOneWidget);
  });

  testWidgets('long output is collapsed and opens on demand', (t) async {
    await t.pumpWidget(
      app(
        const AgentEntryView(CommandEntry('ls', output: ['one', 'two', 'three', 'four', 'five'])),
      ),
    );
    SelectableText output() => t.widget(find.byType(SelectableText).last);
    expect(output().data, 'one\ntwo\nthree');
    await t.tap(find.text('Show 2 more lines'));
    await t.pump();
    expect(output().data, 'one\ntwo\nthree\nfour\nfive');
    await t.tap(find.text('Show less'));
    await t.pump();
    expect(output().data, 'one\ntwo\nthree');
  });

  testWidgets('short output has no toggle', (t) async {
    await t.pumpWidget(app(const AgentEntryView(CommandEntry('ls', output: ['one']))));
    expect(find.byKey(const Key('agent-output-toggle')), findsNothing);
  });

  testWidgets('a command state is shown only when the screen states it', (t) async {
    await t.pumpWidget(app(const AgentEntryView(CommandEntry('ls'))));
    expect(find.text('Succeeded'), findsNothing);
    expect(find.text('Failed'), findsNothing);
    await t.pumpWidget(app(const AgentEntryView(CommandEntry('ls', state: CommandState.failed))));
    expect(find.text('Failed'), findsOneWidget);
  });

  testWidgets('diff rows carry a sign, not only a color', (t) async {
    await t.pumpWidget(
      app(
        const AgentEntryView(
          EditEntry(
            'a.ts',
            diff: [DiffRow(DiffKind.removed, 'old'), DiffRow(DiffKind.added, 'new')],
          ),
        ),
      ),
    );
    expect(find.text('− old'), findsOneWidget);
    expect(find.text('+ new'), findsOneWidget);
  });

  group('agentDisplayName', () {
    test('names every supported agent and keeps other titles', () {
      expect(agentDisplayName('claude'), 'Claude Code');
      expect(agentDisplayName('opencode'), 'OpenCode');
      expect(agentDisplayName('Terminal'), 'Terminal');
    });
  });

  testWidgets('the compact composer pastes from the + menu', (t) async {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.getData') return {'text': 'pasted'};
      return null;
    });
    addTearDown(
      () =>
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    var text = '';
    await t.pumpWidget(
      app(
        ChatComposer(
          compact: true,
          initialText: '',
          attachments: const [],
          onSend: (_) {},
          onChanged: (v) => text = v,
          onAttach: () {},
          onRemoveAttachment: (_) {},
          onClose: null,
        ),
      ),
    );
    expect(find.byKey(const Key('chat-paste')), findsNothing);
    await t.tap(find.byKey(const Key('chat-more')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('chat-paste')));
    await t.pumpAndSettle();
    expect(text, 'pasted');
  });
}
