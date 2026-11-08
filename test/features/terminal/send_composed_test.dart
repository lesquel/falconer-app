import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';

void main() {
  test('images get time to attach before Enter, all in one send', () async {
    final log = <String>[];
    await sendComposed(
      files: ['/u/a.jpg', '/u/b.jpg'],
      text: 'look at these',
      paste: (s) => log.add('paste $s'),
      send: (s) async => log.add('send ${s == '\r' ? 'enter' : s}'),
      wait: (d) async => log.add('wait ${d.inMilliseconds}'),
    );
    expect(log, [
      'paste /u/a.jpg',
      'send  ',
      'paste /u/b.jpg',
      'send  ',
      'wait 950',
      'paste look at these',
      'send enter',
    ]);
  });

  test('text alone is sent at once', () async {
    final log = <String>[];
    await sendComposed(
      files: const [],
      text: 'hi',
      paste: (s) => log.add('paste $s'),
      send: (s) async => log.add('send'),
      wait: (d) async => log.add('wait'),
    );
    expect(log, ['paste hi', 'send']);
  });
}
