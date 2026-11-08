import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/presentation/controllers/chat_attachment.dart';
import 'package:openmosh/features/terminal/presentation/views/chat_composer.dart';

// 1x1 transparent PNG.
final _png = Uint8List.fromList([
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  13,
  73,
  68,
  65,
  84,
  120,
  156,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  45,
  180,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
]);

void main() {
  Future<(List<String>, List<int>, List<String>)> pump(
    WidgetTester t, {
    List<ChatAttachment> attachments = const [],
  }) async {
    final sent = <String>[];
    final removed = <int>[];
    final drafts = <String>[];
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            initialText: '',
            attachments: attachments,
            onSend: sent.add,
            onChanged: drafts.add,
            onAttach: () {},
            onRemoveAttachment: removed.add,
            onClose: () {},
          ),
        ),
      ),
    );
    return (sent, removed, drafts);
  }

  testWidgets('sends the whole message, multi-line included, and clears the draft', (t) async {
    final (sent, _, drafts) = await pump(t);
    await t.enterText(find.byKey(const Key('chat-input')), 'fix the bug\nthen run tests');
    await t.tap(find.byTooltip('Send'));
    expect(sent, ['fix the bug\nthen run tests']);
    expect(drafts.last, '');
  });

  testWidgets('blank messages without attachments are not sent', (t) async {
    final (sent, _, _) = await pump(t);
    await t.enterText(find.byKey(const Key('chat-input')), '   ');
    await t.tap(find.byTooltip('Send'));
    expect(sent, isEmpty);
  });

  testWidgets('attachments show as thumbnails, can be removed and sent alone', (t) async {
    final (sent, removed, _) = await pump(
      t,
      attachments: [
        ChatAttachment(
          remotePath: '/h/.openmosh/uploads/a1-shot.png',
          name: 'shot.png',
          preview: _png,
        ),
        const ChatAttachment(remotePath: '/h/.openmosh/uploads/b2-notes.txt', name: 'notes.txt'),
      ],
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.textContaining('.openmosh'), findsNothing);
    await t.tap(find.byTooltip('Remove notes.txt'));
    expect(removed, [1]);
    await t.tap(find.byTooltip('Send'));
    expect(sent, ['']);
  });
}
