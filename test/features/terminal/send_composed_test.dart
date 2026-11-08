import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/terminal/presentation/controllers/terminal_session.dart';

void main() {
  test('everything goes through one ordered channel: images, then text, then Enter', () async {
    final log = <String>[];
    await sendComposed(
      files: ['/u/a.jpg', '/u/b.jpg'],
      text: 'look at these',
      bracketed: true,
      send: (s) async => log.add('send ${s == '\r' ? 'enter' : s}'),
      wait: (d) async => log.add('wait ${d.inMilliseconds}'),
    );
    expect(log, [
      'send \x1b[200~/u/a.jpg\x1b[201~',
      'send  ',
      'send \x1b[200~/u/b.jpg\x1b[201~',
      'send  ',
      'wait 950',
      'send \x1b[200~look at these\nAttached image: /u/a.jpg\nAttached image: /u/b.jpg\x1b[201~',
      'wait 400',
      'send enter',
    ]);
  });

  test('text alone is pasted, then Enter after a short pause', () async {
    final log = <String>[];
    await sendComposed(
      files: const [],
      text: 'hi',
      bracketed: false,
      send: (s) async => log.add(s),
      wait: (d) async => log.add('wait'),
    );
    expect(log, ['hi', 'wait', '\r']);
  });

  test('a paste cannot end the bracket early', () async {
    final log = <String>[];
    await sendComposed(
      files: const [],
      text: 'a\x1b[201~b',
      bracketed: true,
      send: (s) async => log.add(s),
      wait: (_) async {},
    );
    expect(log.first, '\x1b[200~a[201~b\x1b[201~');
  });

  test('attachment lines name images and files; an empty message still lists them', () {
    expect(
      withAttachmentLines('', ['/u/x.PNG', '/u/log.txt']),
      'Attached image: /u/x.PNG\nAttached file: /u/log.txt',
    );
    expect(withAttachmentLines('hi', ['/u/a.jpg']), 'hi\nAttached image: /u/a.jpg');
  });
}
