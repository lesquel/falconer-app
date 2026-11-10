import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openmosh/features/voice/data/repositories/file_model_store.dart';
import 'package:openmosh/features/voice/domain/entities/voice_model.dart';
import 'package:openmosh/features/voice/domain/repositories/voice_ports.dart';

import 'archive_extractor_test.dart' show tarBz2;

void main() {
  late Directory root;
  late List<Uri> requests;
  setUp(() {
    root = Directory.systemTemp.createTempSync('voice_store_');
    requests = [];
  });
  tearDown(() => root.deleteSync(recursive: true));

  final archive = tarBz2({
    'w/tiny-encoder.int8.onnx': 'e',
    'w/tiny-encoder.onnx': 'big',
    'w/tiny-decoder.int8.onnx': 'd',
    'w/tiny-tokens.txt': 't',
  });
  final goodSha = sha256.convert(archive).toString();

  VoiceModel model({
    String? sha,
    int? size,
    bool custom = false,
    String url = 'https://x/a.tar.bz2',
  }) => VoiceModel(
    id: custom ? 'custom-1' : 'whisper-tiny',
    name: 'T',
    url: url,
    sha256: sha ?? goodSha,
    sizeBytes: custom ? null : (size ?? archive.length),
    family: ModelFamily.whisper,
    custom: custom,
    files: custom
        ? const {}
        : const {
            ModelRole.encoder: 'w/tiny-encoder.int8.onnx',
            ModelRole.decoder: 'w/tiny-decoder.int8.onnx',
            ModelRole.tokens: 'w/tiny-tokens.txt',
          },
  );

  FileModelStore store({List<int>? body}) => FileModelStore(
    root: () async => root,
    client: () => MockClient.streaming((req, _) async {
      requests.add(req.url);
      return http.StreamedResponse(Stream.value(body ?? archive), 200);
    }),
  );

  List<String> leftovers() => root.listSync().map((e) => e.path.split('/').last).toList();

  test('creating the store and listing models never downloads anything', () async {
    final s = store();
    expect(await s.installed(), isEmpty);
    expect(requests, isEmpty);
  });

  test('a verified download is unpacked atomically and keeps only the needed files', () async {
    final s = store();
    final progress = <int>[];
    final m = await s.download(
      model(),
      onProgress: (r, _) => progress.add(r),
      cancel: DownloadCancel(),
    );
    expect(requests, hasLength(1));
    expect(progress.last, archive.length);
    expect(await s.installed(), {'whisper-tiny'});
    expect(leftovers(), ['whisper-tiny']);
    final dir = await s.folderOf('whisper-tiny');
    expect(File('$dir/w/tiny-encoder.int8.onnx').existsSync(), isTrue);
    expect(File('$dir/w/tiny-encoder.onnx').existsSync(), isFalse);
    expect(m.files[ModelRole.tokens], 'w/tiny-tokens.txt');
  });

  test('a SHA-256 mismatch is rejected and the .part file is removed', () async {
    final s = store();
    await expectLater(
      s.download(
        model(sha: '0' * 64),
        onProgress: (_, _) {},
        cancel: DownloadCancel(),
      ),
      throwsA(isA<ChecksumMismatch>()),
    );
    expect(leftovers(), isEmpty);
    expect(await s.installed(), isEmpty);
  });

  test('a size different from the pinned one is rejected', () async {
    final s = store();
    await expectLater(
      s.download(
        model(size: archive.length - 1),
        onProgress: (_, _) {},
        cancel: DownloadCancel(),
      ),
      throwsA(isA<ChecksumMismatch>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('a cancelled download leaves nothing behind', () async {
    final gate = StreamController<List<int>>();
    final s = FileModelStore(
      root: () async => root,
      client: () => MockClient.streaming((req, _) async => http.StreamedResponse(gate.stream, 200)),
    );
    final cancel = DownloadCancel();
    final f = s.download(model(), onProgress: (_, _) {}, cancel: cancel);
    gate.add(archive.sublist(0, 10));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    cancel.cancel();
    await expectLater(f, throwsA(isA<DownloadCancelled>()));
    await gate.close();
    expect(leftovers(), isEmpty);
  });

  test('non-https URLs are refused before any request', () async {
    final s = store();
    await expectLater(
      s.download(
        model(url: 'http://x/a.tar.bz2'),
        onProgress: (_, _) {},
        cancel: DownloadCancel(),
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(requests, isEmpty);
  });

  test('a custom model has its files detected after extraction', () async {
    final s = store();
    final m = await s.download(
      model(custom: true),
      onProgress: (_, _) {},
      cancel: DownloadCancel(),
    );
    expect(m.files, {
      ModelRole.encoder: 'w/tiny-encoder.int8.onnx',
      ModelRole.decoder: 'w/tiny-decoder.int8.onnx',
      ModelRole.tokens: 'w/tiny-tokens.txt',
    });
    expect(await s.installed(), {'custom-1'});
  });

  test('a custom archive missing needed files fails and leaves nothing', () async {
    final bad = tarBz2({'w/readme.txt': 'x'});
    final s = store(body: bad);
    await expectLater(
      s.download(
        model(custom: true, sha: sha256.convert(bad).toString()),
        onProgress: (_, _) {},
        cancel: DownloadCancel(),
      ),
      throwsA(isA<Exception>()),
    );
    expect(leftovers(), isEmpty);
  });

  test('delete frees the model folder', () async {
    final s = store();
    await s.download(model(), onProgress: (_, _) {}, cancel: DownloadCancel());
    await s.delete('whisper-tiny');
    expect(await s.installed(), isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('stale partial files from an interrupted run are not usable and get cleaned', () async {
    File('${root.path}/whisper-tiny.part').writeAsStringSync('half');
    Directory('${root.path}/whisper-tiny.extracting').createSync();
    final s = store();
    expect(await s.installed(), isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('with no network, installed models are still listed and found (S10)', () async {
    await store().download(model(), onProgress: (_, _) {}, cancel: DownloadCancel());
    final offline = FileModelStore(
      root: () async => root,
      client: () => throw StateError('network used in airplane mode'),
    );
    expect(await offline.installed(), {'whisper-tiny'});
    expect(Directory(await offline.folderOf('whisper-tiny')).existsSync(), isTrue);
  });
}
