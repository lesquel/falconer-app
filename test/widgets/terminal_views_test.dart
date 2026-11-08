import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/presentation/views/session_ended_panel.dart';

void main() {
  testWidgets('ended session offers reconnect and back', (t) async {
    var reconnects = 0;
    var backs = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionEndedPanel(onReconnect: () => reconnects++, onBack: () => backs++),
        ),
      ),
    );
    await t.tap(find.text('Reconnect'));
    await t.tap(find.text('Back'));
    expect(reconnects, 1);
    expect(backs, 1);
  });
}
