import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/pairing/presentation/views/pair_scan_view.dart';

void main() {
  Widget view({String? error}) => MaterialApp(
    home: Scaffold(
      body: PairScanView(scanner: const Text('camera'), onSubmit: (_) {}, error: error),
    ),
  );

  testWidgets('camera stays on screen after an error so the user can scan again', (t) async {
    await t.pumpWidget(view(error: 'This is not a valid OpenMosh pairing code.'));
    expect(find.text('camera'), findsOneWidget);
    expect(find.text('This is not a valid OpenMosh pairing code.'), findsOneWidget);
  });

  testWidgets('paste field says which link it expects', (t) async {
    await t.pumpWidget(view());
    expect(find.textContaining('openmosh://pair'), findsOneWidget);
    expect(find.textContaining('openmosh-hook pair --uri'), findsOneWidget);
  });
}
