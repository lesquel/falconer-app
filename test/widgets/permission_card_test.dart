import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/theme.dart';
import 'package:openmosh/features/agent_view/domain/entities/screen_block.dart';
import 'package:openmosh/features/agent_view/presentation/views/agent_screen_view.dart';
import 'package:openmosh/l10n/l10n.dart';
import 'package:openmosh/shared/domain/contrast.dart';
import 'package:openmosh/shared/ui/tokens/mosh_colors.dart';

const _menu = ChoiceBlock('Do you want to proceed?', [
  ChoiceOption('Yes', ['1'], true, ChoiceKind.allow),
  ChoiceOption(
    "Yes, and don't ask again for npm install commands in /home/dev/projects/shop",
    ['2'],
    false,
    ChoiceKind.allowAlways,
  ),
  ChoiceOption('No, and tell Claude what to do differently', ['3'], false, ChoiceKind.deny),
  ChoiceOption('Show the diff', ['4'], false, ChoiceKind.other),
], detail: 'npm install\nInstall project dependencies');

void main() {
  Future<void> pump(
    WidgetTester t, {
    List<ScreenBlock> blocks = const [TextBlock('I will install the deps.'), _menu],
    Future<Object?> Function(List<String>)? onChoice,
    ValueChanged<List<String>>? onKeys,
    Brightness brightness = Brightness.dark,
    double textScale = 1,
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        theme: buildTheme(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedAppLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: AgentScreenView(
            title: 'claude',
            blocks: blocks,
            loaded: true,
            onKeys: onKeys ?? (_) {},
            onChoice: onChoice,
            onRetry: () {},
            onTerminalMode: () {},
            composer: const SizedBox(key: Key('composer'), height: 48),
          ),
        ),
      ),
    );
    await t.pump();
  }

  final card = find.byKey(const Key('agent-permission-card'));

  testWidgets('the card is docked above the composer, out of the scrolling list', (t) async {
    await pump(t);
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const Key('agent-blocks')), matching: card),
      findsNothing,
    );
    final cardBottom = t.getBottomLeft(card).dy;
    expect(cardBottom, lessThanOrEqualTo(t.getTopLeft(find.byKey(const Key('composer'))).dy));
    expect(cardBottom, lessThanOrEqualTo(t.getTopLeft(find.byKey(const Key('agent-key-esc'))).dy));
    expect(find.text('claude needs your permission'), findsOneWidget);
    expect(find.text('Do you want to proceed?'), findsOneWidget);
  });

  testWidgets('no card without a menu', (t) async {
    await pump(t, blocks: const [TextBlock('Done.')]);
    expect(card, findsNothing);
    expect(find.byKey(const Key('choice-0')), findsNothing);
  });

  testWidgets('a menu without allow or deny says the agent is asking', (t) async {
    await pump(
      t,
      blocks: const [
        ChoiceBlock('Pick a model', [
          ChoiceOption('Fast', ['1'], true, ChoiceKind.other),
          ChoiceOption('Smart', ['2'], false, ChoiceKind.other),
        ]),
      ],
    );
    expect(find.text('claude is asking'), findsOneWidget);
    expect(find.byKey(const Key('agent-permission-detail')), findsNothing);
  });

  testWidgets('the command it refers to is shown in a monospace block', (t) async {
    await pump(t);
    final detail = find.byKey(const Key('agent-permission-detail'));
    expect(detail, findsOneWidget);
    final text = t.widget<SelectableText>(
      find.descendant(of: detail, matching: find.byType(SelectableText)),
    );
    expect(text.data, 'npm install\nInstall project dependencies');
    expect(text.style?.fontFamily, 'monospace');
  });

  for (final brightness in Brightness.values) {
    testWidgets('buttons by kind, readable in ${brightness.name}', (t) async {
      await pump(t, brightness: brightness);
      final c = MoshColors.of(t.element(card));
      Widget button(int i) => t.widget(find.byKey(Key('choice-$i')));
      expect(button(0), isA<FilledButton>());
      expect(button(1), isA<FilledButton>());
      expect(button(2), isA<OutlinedButton>());
      expect(button(3), isA<TextButton>());

      Color? bg(int i) =>
          (button(i) as ButtonStyleButton).style?.backgroundColor?.resolve(const {});
      Color? fg(int i) =>
          (button(i) as ButtonStyleButton).style?.foregroundColor?.resolve(const {});
      expect(bg(0), c.accent);
      expect(bg(1), isNot(c.accent));
      expect(fg(2), c.danger);
      double ratio(Color a, Color b) => contrastRatio(a.toARGB32(), b.toARGB32());
      expect(ratio(fg(0)!, bg(0)!), greaterThanOrEqualTo(4.5));
      expect(ratio(fg(1)!, bg(1)!), greaterThanOrEqualTo(4.5));
      expect(ratio(fg(2)!, c.surface), greaterThanOrEqualTo(4.5));
      expect(ratio(fg(3)!, c.surface), greaterThanOrEqualTo(4.5));
      for (var i = 0; i < 4; i++) {
        expect(t.getSize(find.byKey(Key('choice-$i'))).height, greaterThanOrEqualTo(48));
      }
    });
  }

  testWidgets('buttons fill the phone width; long labels are shortened, full in semantics', (
    t,
  ) async {
    final semantics = t.ensureSemantics();
    await pump(t);
    final width = t.getSize(card).width;
    expect(t.getSize(find.byKey(const Key('choice-0'))).width, greaterThan(width - 64));
    final long = _menu.options[1].label;
    expect(find.text(long), findsNothing);
    expect(find.text(shortChoiceLabel(long)), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(RegExp.escape(long))), findsOneWidget);
    semantics.dispose();
  });

  test('labels are shortened at a word, short ones kept', () {
    expect(shortChoiceLabel('Yes'), 'Yes');
    final s = shortChoiceLabel(
      "Yes, and don't ask again for npm install commands in /home/dev/projects/shop",
    );
    expect(s.length, lessThanOrEqualTo(45));
    expect(s, endsWith('…'));
    expect(s, startsWith("Yes, and don't ask again"));
  });

  testWidgets("the agent's current option is marked", (t) async {
    await pump(t);
    expect(find.byKey(const Key('choice-selected-0')), findsOneWidget);
    expect(find.byKey(const Key('choice-selected-1')), findsNothing);
  });

  testWidgets('a tap sends the keys once and disables every button with progress', (t) async {
    final sent = <List<String>>[];
    final done = Completer<Object?>();
    await pump(
      t,
      onChoice: (keys) {
        sent.add(keys);
        return done.future;
      },
    );
    await t.tap(find.byKey(const Key('choice-2')));
    await t.pump();
    expect(sent, [
      ['3'],
    ]);
    expect(find.descendant(of: card, matching: find.byType(CircularProgressIndicator)), findsOne);
    for (var i = 0; i < 4; i++) {
      expect((t.widget(find.byKey(Key('choice-$i'))) as ButtonStyleButton).enabled, isFalse);
    }
    await t.tap(find.byKey(const Key('choice-0')), warnIfMissed: false);
    done.complete(null);
    await t.pump();
    // Sent fine: still disabled until the next screen arrives.
    expect((t.widget(find.byKey(const Key('choice-0'))) as ButtonStyleButton).enabled, isFalse);
    expect(sent, hasLength(1));
  });

  testWidgets('a failed send enables the buttons again', (t) async {
    await pump(t, onChoice: (_) async => StateError('offline'));
    await t.tap(find.byKey(const Key('choice-0')));
    await t.pump();
    await t.pump();
    expect((t.widget(find.byKey(const Key('choice-0'))) as ButtonStyleButton).enabled, isTrue);
  });

  testWidgets('a large text scale still fits without overflow', (t) async {
    await pump(t, textScale: 2);
    expect(t.takeException(), isNull);
    expect(card, findsOneWidget);
  });
}
