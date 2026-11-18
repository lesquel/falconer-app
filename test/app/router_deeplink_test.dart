import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:openmosh/app/router.dart';
import 'package:openmosh/features/inbox/domain/entities/suggested_answer.dart';
import 'package:openmosh/features/inbox/presentation/containers/event_confirm_container.dart';
import 'package:openmosh/features/webpush/presentation/containers/webpush_container.dart';

/// Builds the widget the router would show for [location], as if reached
/// with [extra] (in-app navigation) or without it (an external route).
Widget screenFor(BuildContext context, GoRouter router, String location, {Object? extra}) {
  final match = router.configuration.findMatch(Uri.parse(location));
  expect(match.isError, isFalse, reason: location);
  final route = match.last.route;
  final state = GoRouterState(
    router.configuration,
    uri: match.uri,
    matchedLocation: match.uri.path,
    fullPath: match.fullPath,
    pathParameters: match.pathParameters,
    extra: extra,
    pageKey: const ValueKey('test'),
  );
  return route.builder!(context, state);
}

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearDefaultRouteNameTestValue();
  });

  testWidgets('the app starts at home whatever route the platform hands it', (t) async {
    t.binding.platformDispatcher.defaultRouteNameTestValue = '/inbox/h1/ev1?action=allow';
    final router = buildRouter();
    addTearDown(router.dispose);
    expect(router.routeInformationProvider.value.uri.toString(), '/');
  });

  testWidgets('an approve or deny answer in the URL is never preselected', (t) async {
    await t.pumpWidget(const SizedBox());
    final context = t.element(find.byType(SizedBox));
    final router = buildRouter();
    addTearDown(router.dispose);

    final external = screenFor(context, router, '/inbox/h1/ev1?action=allow');
    expect((external as EventConfirmContainer).action, isNull);

    final inApp = screenFor(context, router, '/inbox/h1/ev1', extra: const SuggestedAnswer('deny'));
    expect((inApp as EventConfirmContainer).action, 'deny');
  });

  testWidgets('a Web Push code is never taken from the URL', (t) async {
    await t.pumpWidget(const SizedBox());
    final context = t.element(find.byType(SizedBox));
    final router = buildRouter();
    addTearDown(router.dispose);

    final external = screenFor(context, router, '$webPushRoute?d=abc');
    expect((external as WebPushContainer).code, isNull);

    final inApp = screenFor(context, router, webPushRoute, extra: const WebPushCode('abc'));
    expect((inApp as WebPushContainer).code, 'abc');
  });
}
