import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/features/terminal/presentation/views/chat_composer.dart';
import 'package:openmosh/features/voice/presentation/containers/voice_mic_button.dart';
import 'package:openmosh/shared/data/app_database.dart';

import 'voice_fakes.dart';

void main() {
  testWidgets('dictated text is inserted at the cursor and never sent', (t) async {
    final sent = <String>[];
    final drafts = <String>[];
    late ValueChanged<String> insert;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatComposer(
            initialText: 'run  please',
            attachments: const [],
            onSend: sent.add,
            onChanged: drafts.add,
            onAttach: () {},
            onRemoveAttachment: (_) {},
            onClose: () {},
            micBuilder: (i) {
              insert = i;
              return IconButton(
                key: const Key('mic'),
                icon: const Icon(Icons.mic),
                onPressed: () {},
              );
            },
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('mic')), findsOneWidget);
    final field = t.widget<TextField>(find.byKey(const Key('chat-input')));
    field.controller!.selection = const TextSelection.collapsed(offset: 4);
    insert('the tests');
    await t.pump();
    expect(field.controller!.text, 'run the tests please');
    expect(drafts.last, 'run the tests please');
    expect(sent, isEmpty);
  });

  testWidgets('tapping the mic with no model opens voice settings, no recording', (t) async {
    final recorder = FakeRecorder();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(body: VoiceMicButton(onTranscript: (_) {})),
        ),
        GoRoute(
          path: voiceSettingsRoute,
          builder: (_, _) => const Scaffold(body: Text('voice settings')),
        ),
      ],
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: voiceOverrides(db, FakeModelStore(), recorder),
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await t.runAsync(() async {
      await t.tap(find.byKey(const Key('chat-mic')));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await t.pumpAndSettle();
    expect(find.text('voice settings'), findsOneWidget);
    expect(recorder.calls, isEmpty);
  });

  testWidgets('the mic closes cleanly when it was never used', (t) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await t.pumpWidget(
      ProviderScope(
        overrides: voiceOverrides(db, FakeModelStore(), FakeRecorder()),
        child: MaterialApp(
          home: Scaffold(body: VoiceMicButton(onTranscript: (_) {})),
        ),
      ),
    );
    await t.pumpWidget(const SizedBox());
    expect(t.takeException(), isNull);
  });
}
