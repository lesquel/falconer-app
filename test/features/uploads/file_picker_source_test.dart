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
  late List<String> images;
  late FilePickerSource source;

  setUp(() {
    root = Directory.systemTemp.createTempSync('openmosh_picker_');
    cache = Directory('${root.path}/cache')..createSync();
    next = [];
    images = [];
    source = FilePickerSource(
      pickFiles: (_) async => next,
      pickImagePaths: () async => images,
      cacheDir: () async => cache,
    );
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

  test('photo picker returns every selected image; cache copies are temporary', () async {
    final a = File('${cache.path}/scaled_a.jpg')..writeAsBytesSync([1, 2]);
    final b = File('${cache.path}/scaled_b.png')..writeAsBytesSync([3]);
    images = [a.path, b.path];
    final picked = await source.pickImages();
    expect([for (final f in picked) f.name], ['scaled_a.jpg', 'scaled_b.png']);
    expect([for (final f in picked) f.size], [2, 1]);
    expect(picked.every((f) => f.temporary), isTrue);
    await source.discard(picked.first);
    expect(a.existsSync(), isFalse);
  });

  test('cancelled photo picker returns nothing', () async {
    expect(await source.pickImages(), isEmpty);
  });

  test('an oversized image fails the whole pick and its cache copies are removed', () async {
    final small = File('${cache.path}/ok.jpg')..writeAsBytesSync([1]);
    final big = File('${cache.path}/big.jpg');
    final raf = big.openSync(mode: FileMode.write)..setPositionSync(50 * 1024 * 1024 + 1);
    raf
      ..writeByteSync(0)
      ..closeSync();
    images = [small.path, big.path];
    await expectLater(source.pickImages(), throwsA(isA<ValidationFailure>()));
    expect(small.existsSync(), isFalse);
    expect(big.existsSync(), isFalse);
  });
}
