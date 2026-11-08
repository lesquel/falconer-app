import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/uploads/data/datasources/file_picker_source.dart';
import 'package:openmosh/shared/domain/failure.dart';

final class LocalFile extends PlatformFile {
  LocalFile(this.file);
  final File file;
  @override
  String get name => file.uri.pathSegments.last;
  @override
  Uri get uri => file.uri;
  @override
  get xFile => throw UnimplementedError();
  @override
  int? lengthSync() => file.lengthSync();
  @override
  Future<int?> length() async => file.lengthSync();
  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() => file.openRead().map(Uint8List.fromList);
}

void main() {
  late Directory root;
  late Directory cache;
  late List<PlatformFile> next;
  late FilePickerSource source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('openmosh_picker_');
    cache = Directory('${root.path}/cache')..createSync();
    next = [];
    source = FilePickerSource(pickFiles: (_) async => next, cacheDir: () async => cache);
  });
  tearDown(() => root.deleteSync(recursive: true));

  test('a picked copy inside the app cache is temporary and deleted by discard', () async {
    final stamp = Directory('${cache.path}/file_picker/1700')..createSync(recursive: true);
    final f = File('${stamp.path}/shot.png')..writeAsBytesSync([1, 2, 3]);
    next = [LocalFile(f)];
    final picked = (await source.pick(imagesOnly: true))!;
    expect(picked.temporary, isTrue);
    expect(picked.path, f.path);
    await source.discard(picked);
    expect(f.existsSync(), isFalse);
    expect(stamp.existsSync(), isFalse);
  });

  test('a file outside the app cache is never deleted', () async {
    final f = File('${root.path}/Downloads/keep.txt')
      ..createSync(recursive: true)
      ..writeAsStringSync('x');
    next = [LocalFile(f)];
    final picked = (await source.pick(imagesOnly: false))!;
    expect(picked.temporary, isFalse);
    await source.discard(picked);
    expect(f.existsSync(), isTrue);
  });

  test('a path that only looks like the cache via .. is not treated as cache', () async {
    final f = File('${root.path}/outside.txt')..writeAsStringSync('x');
    next = [LocalFile(File('${cache.path}/../outside.txt'))];
    final picked = (await source.pick(imagesOnly: false))!;
    expect(picked.temporary, isFalse);
    await source.discard(picked);
    expect(f.existsSync(), isTrue);
  });

  test('an oversized picked copy in the cache is deleted when refused', () async {
    final f = File('${cache.path}/file_picker/1/big.bin')..createSync(recursive: true);
    f.writeAsBytesSync(List<int>.filled(50 * 1024 * 1024 + 1, 0));
    next = [LocalFile(f)];
    await expectLater(source.pick(imagesOnly: false), throwsA(isA<ValidationFailure>()));
    expect(f.existsSync(), isFalse);
  });
}
