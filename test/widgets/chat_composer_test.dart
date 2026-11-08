import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/presentation/views/chat_composer.dart';

void main() {
  Future<(List<String>, List<String>)> pump(
    WidgetTester t, {
    String initial = '',
    Future<String?> Function()? attach,
  }) async {
    final sent = <String>[];
    final drafts = <String>[];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            initialText: initial,
            onSend: sent.add,
            onChanged: drafts.add,
            onAttach: attach ?? () async => null,
            onClose: () {},
          ),
        ),
      ),
    );
    return (sent, drafts);
  }

  testWidgets('sends the whole message, multi-line included, and clears the draft', (t) async {
    final (sent, drafts) = await pump(t);
    await t.enterText(find.byKey(const Key('chat-input')), 'fix the bug\nthen run tests');
    await t.tap(find.byTooltip('Send'));
    expect(sent, ['fix the bug\nthen run tests']);
    expect(drafts.last, '');
    expect(find.text('fix the bug\nthen run tests'), findsNothing);
  });

  testWidgets('blank messages are not sent', (t) async {
    final (sent, _) = await pump(t);
    await t.enterText(find.byKey(const Key('chat-input')), '   ');
    await t.tap(find.byTooltip('Send'));
    expect(sent, isEmpty);
  });

  testWidgets('keeps the saved draft and inserts attached paths', (t) async {
    final (sent, _) = await pump(
      t,
      initial: 'look at',
      attach: () async => '~/.openmosh/uploads/a1_shot.png',
    );
    await t.tap(find.byTooltip('Attach images or files'));
    await t.pump();
    await t.tap(find.byTooltip('Send'));
    expect(sent.single.trim(), 'look at ~/.openmosh/uploads/a1_shot.png');
  });
}
