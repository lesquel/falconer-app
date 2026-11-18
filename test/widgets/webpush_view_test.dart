import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/webpush/presentation/views/webpush_view.dart';

import '../support/l10n_app.dart';

Widget _view({Locale locale = const Locale('en')}) => l10nApp(
  locale: locale,
  home: Scaffold(
    body: WebPushView(
      serviceHost: 'web.push.apple.com',
      busy: false,
      hosts: null,
      onConfirm: () {},
      onClose: () {},
    ),
  ),
);

String _text(WidgetTester t, String key) => t.widget<Text>(find.byKey(Key(key))).data!;

void main() {
  testWidgets('the confirm screen names the destination and says it replaces the current one', (
    t,
  ) async {
    await t.pumpWidget(_view());
    await t.pumpAndSettle();
    expect(_text(t, 'webpush_destination'), contains('web.push.apple.com'));
    expect(_text(t, 'webpush_replaces'), contains('replaces'));
    expect(find.byKey(const Key('webpush_confirm')), findsOneWidget);
  });

  testWidgets('the destination warning is translated to Spanish', (t) async {
    await t.pumpWidget(_view(locale: const Locale('es')));
    await t.pumpAndSettle();
    expect(_text(t, 'webpush_destination'), contains('web.push.apple.com'));
    expect(_text(t, 'webpush_replaces'), contains('reemplaza'));
  });
}
