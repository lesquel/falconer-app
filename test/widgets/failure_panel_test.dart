import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/shared/domain/failure.dart';
import 'package:openmosh/shared/ui/organisms/failure_panel.dart';

void main() {
  testWidgets('host key mismatch shows both fingerprints and no way to continue', (t) async {
    var retried = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FailurePanel(
            failure: const HostKeyMismatchFailure(
              expected: 'SHA256:pinned',
              actual: 'SHA256:other',
            ),
            onRetry: () => retried = true,
            onBack: () {},
          ),
        ),
      ),
    );
    expect(find.text('Host key changed'), findsOneWidget);
    expect(find.text('SHA256:pinned'), findsNothing, reason: 'masked until revealed');
    expect(find.byTooltip('Show to compare'), findsNWidgets(2));
    await t.tap(find.byTooltip('Show to compare').first);
    await t.tap(find.byTooltip('Show to compare').last);
    await t.pump();
    expect(find.text('SHA256:pinned'), findsOneWidget);
    expect(find.text('SHA256:other'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(
      find.textContaining(RegExp('continue|anyway|trust', caseSensitive: false)),
      findsNothing,
    );
    expect(find.text('Back'), findsOneWidget);
    expect(retried, isFalse);
  });

  testWidgets('other failures offer retry', (t) async {
    var retried = false;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FailurePanel(failure: const ConnectionFailure(), onRetry: () => retried = true),
        ),
      ),
    );
    await t.tap(find.text('Retry'));
    expect(retried, isTrue);
  });
}
