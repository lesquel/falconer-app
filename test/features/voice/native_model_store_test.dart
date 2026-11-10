import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openmosh/features/voice/data/repositories/file_model_store.dart';
import 'package:openmosh/features/voice/domain/entities/voice_model.dart';
import 'package:openmosh/features/voice/domain/repositories/voice_ports.dart';

/// In-memory system downloader: [content] is what each URL serves.
class FakeNativeDownloader implements NativeDownloader {
  FakeNativeDownloader(this.content);
  final Map<String, List<int>> content;
  final enqueued = <String>[];
  final removed = <int>[];
  final jobs = <int, NativeDownload>{};
  final _urls = <int, String>{};
  var _next = 1;

  /// New downloads stay running until [finish].
  bool hold = false;
  NativeDownloadStatus outcome = NativeDownloadStatus.done;

  void seed(String path, String url, NativeDownloadStatus status) {
    final id = _next++;
    _urls[id] = url;
    jobs[id] = NativeDownload(id: id, path: path, status: status, received: 1, total: 1);
  }

  void finish() {
    for (final e in jobs.entries.toList()) {
      jobs[e.key] = NativeDownload(id: e.key, path: e.value.path, status: outcome);
    }
  }

  @override
  Future<int> enqueue({required String url, required String path, required String title}) async {
    enqueued.add(url);
    final id = _next++;
    _urls[id] = url;
    final n = content[url]?.length ?? 0;
    jobs[id] = NativeDownload(
      id: id,
      path: path,
      status: hold ? NativeDownloadStatus.running : outcome,
      received: hold ? 0 : n,
      total: n,
    );
    return id;
  }

  @override
  Future<List<NativeDownload>> list() async => jobs.values.toList();

  @override
  Future<void> remove(List<int> ids) async {
    removed.addAll(ids);
    ids.forEach(jobs.remove);
  }

  @override
  Future<bool> adopt({
    required String path,
    required String dest,
    required String sha256,
    required int size,
  }) async {
    final job = jobs.values.where((j) => j.path == path).firstOrNull;
    final bytes = job == null ? null : content[_urls[job.id]];
    if (job?.status != NativeDownloadStatus.done || bytes == null) return false;
    if (bytes.length != size || sha256Of(bytes) != sha256) return false;
    File(dest)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(bytes);
    return true;
  }
}

String sha256Of(List<int> b) => sha256.convert(b).toString();

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('voice_native_'));
  tearDown(() => root.deleteSync(recursive: true));

  final files = {
    'w/tiny-encoder.int8.onnx': utf8.encode('encoder'),
    'w/tiny-decoder.int8.onnx': utf8.encode('decoder'),
    'w/tiny-tokens.txt': utf8.encode('tokens'),
  };
  String urlOf(String path) => 'https://huggingface.co/r/resolve/abc/${path.split('/').last}';
  Map<String, List<int>> served() => {for (final e in files.entries) urlOf(e.key): e.value};

  final model = VoiceModel(
    id: 'whisper-tiny',
    name: 'Whisper Tiny',
    url: 'https://huggingface.co/r',
    sha256: '',
    family: ModelFamily.whisper,
    sizeBytes: files.values.fold(0, (a, b) => a! + b.length),
    files: const {
      ModelRole.encoder: 'w/tiny-encoder.int8.onnx',
      ModelRole.decoder: 'w/tiny-decoder.int8.onnx',
      ModelRole.tokens: 'w/tiny-tokens.txt',
    },
    parts: [
      for (final e in files.entries)
        ModelPart(
          path: e.key,
          url: urlOf(e.key),
          sizeBytes: e.value.length,
          sha256: sha256Of(e.value),
        ),
    ],
  );

  FileModelStore store(NativeDownloader native) => FileModelStore(
    root: () async => root,
    native: native,
    poll: Duration.zero,
    client: () => throw StateError('the archive path must not be used'),
  );

  List<String> leftovers() => root.listSync().map((e) => e.path.split('/').last).toList();

  test('listing and reconciling never ask the system downloader for anything', () async {
    final n = FakeNativeDownloader(served());
    final s = store(n);
    expect(await s.installed(), isEmpty);
    expect(await s.interrupted({'whisper-tiny'}), isEmpty);
    expect(n.enqueued, isEmpty);
  });

  test('each file is fetched by the system, checked natively and moved into place', () async {
    final n = FakeNativeDownloader(served());
    final s = store(n);
    final progress = <int>[];
    final ready = await s.download(
      model,
      onProgress: (r, _) => progress.add(r),
      cancel: DownloadCancel(),
    );
    expect(n.enqueued, [for (final p in files.keys) urlOf(p)]);
    expect(await s.installed(), {'whisper-tiny'});
    expect(leftovers(), ['whisper-tiny']);
    final dir = await s.folderOf('whisper-tiny');
    for (final e in files.entries) {
      expect(File('$dir/${e.key}').readAsBytesSync(), e.value);
    }
    expect(ready.files, model.files);
    expect(progress.last, model.sizeBytes);
    expect(n.jobs, isEmpty, reason: 'staging copies are deleted once adopted');
  });

  test('a file that does not match its SHA-256 installs nothing and removes everything', () async {
    final bad = served()..[urlOf('w/tiny-tokens.txt')] = utf8.encode('tampered');
    final n = FakeNativeDownloader(bad);
    final s = store(n);
    await expectLater(
      s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel()),
      throwsA(isA<ChecksumMismatch>()),
    );
    expect(await s.installed(), isEmpty);
    expect(leftovers(), isEmpty);
    expect(n.jobs, isEmpty);
  });

  test('cancel stops the system downloads and leaves nothing', () async {
    final n = FakeNativeDownloader(served())..hold = true;
    final s = store(n);
    final cancel = DownloadCancel();
    final f = s.download(model, onProgress: (_, _) {}, cancel: cancel);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(n.jobs, hasLength(3));
    cancel.cancel();
    await expectLater(f, throwsA(isA<DownloadCancelled>()));
    expect(n.jobs, isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('a download the system gave up on is cleaned up', () async {
    final n = FakeNativeDownloader(served())..outcome = NativeDownloadStatus.failed;
    final s = store(n);
    await expectLater(
      s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel()),
      throwsA(isA<NativeDownloadFailed>()),
    );
    expect(n.jobs, isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('a download finished while the app was closed is adopted without a new request', () async {
    final n = FakeNativeDownloader(served());
    for (final p in files.keys) {
      n.seed('whisper-tiny/$p', urlOf(p), NativeDownloadStatus.done);
    }
    final s = store(n);
    expect(await s.interrupted({'whisper-tiny'}), {'whisper-tiny'});
    await s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel(), resumeOnly: true);
    expect(n.enqueued, isEmpty);
    expect(await s.installed(), {'whisper-tiny'});
    expect(n.jobs, isEmpty);
  });

  test('a finished download that fails its check is cleaned up, not adopted', () async {
    final bad = served()..[urlOf('w/tiny-encoder.int8.onnx')] = utf8.encode('swapped');
    final n = FakeNativeDownloader(bad);
    for (final p in files.keys) {
      n.seed('whisper-tiny/$p', urlOf(p), NativeDownloadStatus.done);
    }
    final s = store(n);
    await expectLater(
      s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel(), resumeOnly: true),
      throwsA(isA<ChecksumMismatch>()),
    );
    expect(await s.installed(), isEmpty);
    expect(n.jobs, isEmpty);
    expect(n.enqueued, isEmpty);
  });

  test('resuming with a file gone cleans up and never starts a new download (S1)', () async {
    final n = FakeNativeDownloader(served());
    n.seed('whisper-tiny/w/tiny-tokens.txt', urlOf('w/tiny-tokens.txt'), NativeDownloadStatus.done);
    final s = store(n);
    await expectLater(
      s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel(), resumeOnly: true),
      throwsA(isA<DownloadCancelled>()),
    );
    expect(n.enqueued, isEmpty);
    expect(n.jobs, isEmpty);
    expect(leftovers(), isEmpty);
  });

  test('leftovers of unknown or already installed models are removed on reconcile', () async {
    final n = FakeNativeDownloader(served());
    n.seed('gone-model/x.onnx', 'https://h/x', NativeDownloadStatus.running);
    n.seed('whisper-tiny/w/tiny-tokens.txt', urlOf('w/tiny-tokens.txt'), NativeDownloadStatus.done);
    Directory('${root.path}/whisper-tiny').createSync();
    final s = store(n);
    expect(await s.interrupted({'whisper-tiny'}), isEmpty);
    expect(n.jobs, isEmpty);
    expect(await s.installed(), {'whisper-tiny'});
  });

  test('without the system downloader each file is fetched and verified in Dart', () async {
    final requests = <Uri>[];
    final s = FileModelStore(
      root: () async => root,
      client: () => MockClient.streaming((req, _) async {
        requests.add(req.url);
        return http.StreamedResponse(Stream.value(served()[req.url.toString()]!), 200);
      }),
    );
    await s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel());
    expect(requests, hasLength(3));
    expect(await s.installed(), {'whisper-tiny'});
    final dir = await s.folderOf('whisper-tiny');
    expect(File('$dir/w/tiny-tokens.txt').readAsStringSync(), 'tokens');
  });

  test('without the system downloader a wrong file installs nothing', () async {
    final s = FileModelStore(
      root: () async => root,
      client: () => MockClient.streaming(
        (req, _) async => http.StreamedResponse(Stream.value(utf8.encode('nope')), 200),
      ),
    );
    await expectLater(
      s.download(model, onProgress: (_, _) {}, cancel: DownloadCancel()),
      throwsA(isA<ChecksumMismatch>()),
    );
    expect(leftovers(), isEmpty);
  });
}
