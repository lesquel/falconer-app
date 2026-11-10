import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/voice/data/datasources/archive_extractor.dart';
import 'package:openmosh/features/voice/domain/repositories/voice_ports.dart';

/// A `.tar.bz2` holding [entries] (name → text, or a symlink target after `->`).
Uint8List tarBz2(Map<String, String> entries) {
  final a = Archive();
  for (final e in entries.entries) {
    if (e.value.startsWith('->')) {
      a.add(ArchiveFile.symlink(e.key, e.value.substring(2)));
    } else {
      a.add(ArchiveFile.bytes(e.key, e.value.codeUnits));
    }
  }
  return BZip2Encoder().encodeBytes(TarEncoder().encodeBytes(a));
}

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('voice_extract_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  String write(Map<String, String> entries) {
    final f = File('${tmp.path}/a.tar.bz2')..writeAsBytesSync(tarBz2(entries));
    return f.path;
  }

  test('extracts regular files and returns their relative paths', () {
    final out = '${tmp.path}/out';
    final paths = extractTarBz2(write({'m/tokens.txt': 'a b', 'm/x.onnx': 'w'}), out);
    expect(paths, unorderedEquals(['m/tokens.txt', 'm/x.onnx']));
    expect(File('$out/m/tokens.txt').readAsStringSync(), 'a b');
  });

  test('only writes the kept files when a keep set is given', () {
    final out = '${tmp.path}/out';
    final paths = extractTarBz2(
      write({'m/tokens.txt': 't', 'm/big.onnx': 'w'}),
      out,
      keep: {'m/tokens.txt'},
    );
    expect(paths, ['m/tokens.txt']);
    expect(File('$out/m/big.onnx').existsSync(), isFalse);
  });

  for (final bad in ['../evil.txt', 'm/../../evil.txt', '/etc/evil.txt']) {
    test('rejects the path traversal entry "$bad"', () {
      final out = '${tmp.path}/out';
      expect(
        () => extractTarBz2(write({'m/ok.txt': 'ok', bad: 'x'}), out),
        throwsA(isA<UnsafeArchive>()),
      );
      expect(File('${tmp.path}/evil.txt').existsSync(), isFalse);
    });
  }

  test('rejects symbolic links', () {
    expect(
      () => extractTarBz2(write({'m/link': '->/etc/passwd'}), '${tmp.path}/out'),
      throwsA(isA<UnsafeArchive>()),
    );
  });

  test('stops when the unpacked files exceed the size budget', () {
    final out = '${tmp.path}/out';
    expect(
      () => extractTarBz2(write({'m/a.bin': 'x' * 600, 'm/b.bin': 'y' * 600}), out, maxBytes: 1000),
      throwsA(isA<UnsafeArchive>()),
    );
  });

  test('the size budget counts only the kept files', () {
    final paths = extractTarBz2(
      write({'m/tokens.txt': 't', 'm/big.onnx': 'w' * 5000}),
      '${tmp.path}/out',
      keep: {'m/tokens.txt'},
      maxBytes: 100,
    );
    expect(paths, ['m/tokens.txt']);
  });
}
