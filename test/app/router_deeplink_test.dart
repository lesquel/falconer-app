import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/router.dart';

void main() {
  final router = buildRouter();
  String? match(String uri) {
    final m = router.configuration.findMatch(Uri.parse(uri));
    return m.isError ? null : m.uri.path;
  }

  test('openmosh:/// links map by path', () {
    expect(match('openmosh:///webpush?d=abc'), '/webpush');
    expect(match('openmosh:///inbox'), '/inbox');
    expect(Uri.parse('openmosh:///webpush?d=abc').queryParameters['d'], 'abc');
  });

  test('openmosh://pair goes to the pair screen; other links are untouched', () {
    expect(deepLinkRedirect(Uri.parse('openmosh://pair?v=3&i=1')), '/pair');
    expect(deepLinkRedirect(Uri.parse('openmosh:///webpush?d=abc')), isNull);
    expect(deepLinkRedirect(Uri.parse('/inbox')), isNull);
  });
}
