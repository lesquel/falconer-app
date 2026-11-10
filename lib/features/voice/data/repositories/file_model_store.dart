import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../domain/entities/model_files.dart';
import '../../domain/entities/voice_model.dart';
import '../../domain/repositories/voice_ports.dart';
import '../datasources/archive_extractor.dart';

final _safeId = RegExp(r'^[a-z0-9][a-z0-9._-]{0,80}$');

/// Upper bound for an archive whose size is not pinned (custom models).
const _maxUnpinnedBytes = 4 * 1024 * 1024 * 1024;

/// Models live in `<root>/<id>/`. A download goes to `<id>.part`, is checked
/// against the pinned SHA-256, unpacked in an isolate into `<id>.extracting/`
/// and renamed to `<id>/` only when complete, so a folder named after a model
/// is always usable.
class FileModelStore implements ModelStore {
  FileModelStore({required this.root, http.Client Function()? client})
    : _client = client ?? http.Client.new;

  /// Folder that holds the models, created on first use.
  final Future<Directory> Function() root;
  final http.Client Function() _client;

  /// Ids being downloaded right now; their partial files are not stale.
  final _active = <String>{};

  static String _checkId(String id) {
    if (!_safeId.hasMatch(id) || id.endsWith('.part') || id.endsWith('.extracting')) {
      throw ArgumentError.value(id, 'id', 'not a safe model id');
    }
    return id;
  }

  Future<Directory> _dir() async {
    final d = await root();
    if (!d.existsSync()) await d.create(recursive: true);
    return d;
  }

  @override
  Future<String> folderOf(String id) async => '${(await _dir()).path}/${_checkId(id)}';

  @override
  Future<Set<String>> installed() async {
    final ids = <String>{};
    await for (final e in (await _dir()).list(followLinks: false)) {
      final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final partial = name.endsWith('.part') || name.endsWith('.extracting');
      if (partial) {
        final id = name.substring(0, name.lastIndexOf('.'));
        // Left by an interrupted download: never usable, free the space.
        if (!_active.contains(id)) await _remove(e.path);
      } else if (e is Directory && _safeId.hasMatch(name)) {
        ids.add(name);
      }
    }
    return ids;
  }

  @override
  Future<void> delete(String id) => folderOf(id).then(_remove);

  static Future<void> _remove(String path) async {
    final type = FileSystemEntity.typeSync(path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return;
    await (type == FileSystemEntityType.directory ? Directory(path) : File(path)).delete(
      recursive: true,
    );
  }

  @override
  Future<VoiceModel> download(
    VoiceModel model, {
    required DownloadProgress onProgress,
    required DownloadCancel cancel,
  }) async {
    final id = _checkId(model.id);
    final uri = Uri.parse(model.url);
    if (uri.scheme != 'https') throw ArgumentError.value(model.url, 'url', 'must be https');
    if (!_active.add(id)) throw StateError('$id is already downloading');
    final dir = (await _dir()).path;
    final part = '$dir/$id.part';
    final staging = '$dir/$id.extracting';
    final target = '$dir/$id';
    try {
      await _remove(part);
      await _remove(staging);
      await _fetch(uri, part, model, onProgress, cancel);
      if (cancel.isCancelled) throw const DownloadCancelled();
      final keep = model.files.isEmpty ? null : model.files.values.toSet();
      final written = await _extract(part, staging, keep);
      await _remove(part);
      if (cancel.isCancelled) throw const DownloadCancelled();
      final files = model.files.isEmpty
          ? detectModelFiles(model.family, written)
          : detectModelFiles(model.family, written.where(keep!.contains));
      if (model.files.isNotEmpty && !_sameFiles(files, model.files)) {
        throw MissingModelFiles(model.family.roles);
      }
      if (model.files.isEmpty) await _prune(staging, written, files.values.toSet());
      await _remove(target);
      await Directory(staging).rename(target);
      return model.withFiles(files);
    } catch (_) {
      await _remove(part);
      await _remove(staging);
      rethrow;
    } finally {
      _active.remove(id);
    }
  }

  /// Off the UI isolate; a static scope so the closure captures only paths.
  static Future<List<String>> _extract(String archive, String into, Set<String>? keep) =>
      Isolate.run(() => extractTarBz2(archive, into, keep: keep));

  static bool _sameFiles(Map<ModelRole, String> a, Map<ModelRole, String> b) =>
      a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  /// Drops what a custom archive ships besides the needed files (test audio,
  /// unused full-precision weights).
  static Future<void> _prune(String folder, List<String> written, Set<String> needed) async {
    for (final rel in written) {
      if (!needed.contains(rel)) await _remove('$folder/$rel');
    }
  }

  Future<void> _fetch(
    Uri uri,
    String part,
    VoiceModel model,
    DownloadProgress onProgress,
    DownloadCancel cancel,
  ) async {
    final client = _client();
    final sink = File(part).openWrite();
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    final limit = model.sizeBytes ?? _maxUnpinnedBytes;
    var received = 0;
    StreamSubscription<List<int>>? sub;
    final done = Completer<void>();
    void fail(Object e) {
      if (!done.isCompleted) done.completeError(e);
    }

    unawaited(cancel.whenCancelled.then((_) => fail(const DownloadCancelled())));
    try {
      final res = await Future.any([
        client.send(http.Request('GET', uri)),
        done.future.then((_) => null),
      ]);
      if (res == null) throw const DownloadCancelled();
      if (res.statusCode != 200) throw DownloadHttpFailure(res.statusCode);
      final total = model.sizeBytes ?? res.contentLength;
      onProgress(0, total);
      sub = res.stream.listen(
        (chunk) {
          received += chunk.length;
          if (received > limit) {
            fail(const ChecksumMismatch());
            return;
          }
          sink.add(chunk);
          hasher.add(chunk);
          onProgress(received, total);
        },
        onError: fail,
        onDone: () {
          if (!done.isCompleted) done.complete();
        },
        cancelOnError: true,
      );
      await done.future;
      hasher.close();
      final size = model.sizeBytes;
      if ((size != null && received != size) || digest.value.toString() != model.sha256) {
        throw const ChecksumMismatch();
      }
    } finally {
      await sub?.cancel();
      await sink.close();
      client.close();
    }
  }
}

final class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
