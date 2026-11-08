import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/keys/data/datasources/key_file_picker.dart';
import 'package:openmosh/shared/domain/failure.dart';

final class DiskFile extends PlatformFile {
  DiskFile(this.file);
  final File file;
  @override
  String get name => file.uri.pathSegments.last;
  @override
  Uri get uri => file.absolute.uri;
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
  late Directory cache;

  setUp(() async => cache = await Directory.systemTemp.createTemp('openmosh-keyfile'));
  tearDown(() async => cache.delete(recursive: true));

  KeyFilePicker picker(File? f) =>
      KeyFilePicker(pick: () async => f == null ? null : DiskFile(f), cacheDir: () async => cache);

  test('reads the key and deletes the picker copy in the app cache', () async {
    final f = File('${cache.path}/id_ed25519')..writeAsStringSync('KEY TEXT');
    expect(await picker(f).pickKeyText(), 'KEY TEXT');
    expect(f.existsSync(), isFalse);
  });

  test('a file outside the cache is left alone', () async {
    final other = await Directory.systemTemp.createTemp('openmosh-keyfile-src');
    addTearDown(() => other.delete(recursive: true));
    final f = File('${other.path}/id')..writeAsStringSync('K');
    expect(await picker(f).pickKeyText(), 'K');
    expect(f.existsSync(), isTrue);
  });

  test('nothing chosen is null; a huge or binary file is refused', () async {
    expect(await picker(null).pickKeyText(), isNull);
    final big = File('${cache.path}/big')..writeAsBytesSync(List.filled(maxKeyFileBytes + 1, 0x41));
    await expectLater(picker(big).pickKeyText(), throwsA(isA<ValidationFailure>()));
    final bin = File('${cache.path}/bin')..writeAsBytesSync([0xff, 0xfe]);
    await expectLater(picker(bin).pickKeyText(), throwsA(isA<ValidationFailure>()));
    expect(big.existsSync() || bin.existsSync(), isFalse);
  });
}
