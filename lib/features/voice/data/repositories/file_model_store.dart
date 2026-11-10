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

/// Models live in `<root>/<id>/`, and a folder named after a model is always
/// usable: files are assembled in `<id>.extracting/` and renamed into place
/// only when every one of them matched its pinned SHA-256.
///
/// A model made of separate files ([VoiceModel.parts], the catalog) is fetched
/// by the system downloader when there is one ([native]: background, resume
/// after network drops, notification), and each file is hashed natively while
/// it is copied into private storage. Without it each file is fetched here.
/// An archive (custom models) goes to `<id>.part`, is checked against its
/// SHA-256 and unpacked in an isolate.
class FileModelStore implements ModelStore {
  FileModelStore({
    required this.root,
    http.Client Function()? client,
    this.native,
    this.poll = const Duration(milliseconds: 500),
  }) : _client = client ?? http.Client.new;

  /// Folder that holds the models, created on first use.
  final Future<Directory> Function() root;
  final http.Client Function() _client;

  /// The phone's download service; null where there is none (tests, desktop).
  final NativeDownloader? native;

  /// How often [native] is asked for progress.
  final Duration poll;

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

  /// Model id of a staging path `<id>/<file>`, or null.
  static String? _ownerOf(String path) {
    final i = path.indexOf('/');
    final id = i <= 0 ? null : path.substring(0, i);
    return id != null && _safeId.hasMatch(id) ? id : null;
  }

  @override
  Future<Set<String>> interrupted(Set<String> known) async {
    final n = native;
    if (n == null) return {};
    final dir = (await _dir()).path;
    final ids = <String>{};
    final stale = <int>[];
    for (final d in await n.list()) {
      final id = _ownerOf(d.path);
      if (id != null && _active.contains(id)) continue;
      final usable =
          id != null &&
          known.contains(id) &&
          d.status != NativeDownloadStatus.failed &&
          !Directory('$dir/$id').existsSync();
      if (usable) {
        ids.add(id);
      } else {
        stale.add(d.id);
      }
    }
    if (stale.isNotEmpty) await n.remove(stale);
    return ids;
  }

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
    bool resumeOnly = false,
  }) async {
    final id = _checkId(model.id);
    final urls = model.parts.isEmpty ? [model.url] : model.parts.map((p) => p.url);
    for (final url in urls) {
      if (Uri.parse(url).scheme != 'https') throw ArgumentError.value(url, 'url', 'must be https');
    }
    if (model.parts.isNotEmpty) _checkParts(model);
    if (resumeOnly && (native == null || model.parts.isEmpty)) throw const DownloadCancelled();
    if (!_active.add(id)) throw StateError('$id is already downloading');
    try {
      final dir = (await _dir()).path;
      if (model.parts.isEmpty) return await _downloadArchive(model, dir, onProgress, cancel);
      final staging = '$dir/$id.extracting';
      await _remove(staging);
      try {
        if (native case final n?) {
          await _downloadNative(n, model, staging, onProgress, cancel, resumeOnly);
        } else {
          await _downloadParts(model, staging, onProgress, cancel);
        }
        if (cancel.isCancelled) throw const DownloadCancelled();
        final target = '$dir/$id';
        await _remove(target);
        await Directory(staging).rename(target);
        return model;
      } catch (_) {
        await _remove(staging);
        rethrow;
      }
    } finally {
      _active.remove(id);
    }
  }

  /// Catalog data, but a part must never point outside the model folder.
  static void _checkParts(VoiceModel model) {
    for (final p in model.parts) {
      final segs = p.path.split('/');
      if (p.path.startsWith('/') || segs.any((s) => s.isEmpty || s == '.' || s == '..')) {
        throw UnsafeArchive(p.path);
      }
    }
  }

  /// The system downloader fetches every file into its staging area; each one
  /// is then hashed while copied into [staging]. Every outcome, success
  /// included, removes the system's copies.
  Future<void> _downloadNative(
    NativeDownloader n,
    VoiceModel model,
    String staging,
    DownloadProgress onProgress,
    DownloadCancel cancel,
    bool resumeOnly,
  ) async {
    String rel(ModelPart p) => '${model.id}/${p.path}';
    final wanted = {for (final p in model.parts) rel(p)};
    final mine = (await n.list()).where((d) => _ownerOf(d.path) == model.id).toList();
    final ids = <String, int>{};
    final stale = <int>[];
    for (final d in mine) {
      final keep =
          wanted.contains(d.path) &&
          d.status != NativeDownloadStatus.failed &&
          !ids.containsKey(d.path);
      keep ? ids[d.path] = d.id : stale.add(d.id);
    }
    if (stale.isNotEmpty) await n.remove(stale);
    try {
      if (resumeOnly && !wanted.every(ids.containsKey)) throw const DownloadCancelled();
      final total = model.sizeBytes;
      final parts = model.parts;
      for (var i = 0; i < parts.length; i++) {
        if (cancel.isCancelled) throw const DownloadCancelled();
        final path = rel(parts[i]);
        if (ids.containsKey(path)) continue;
        ids[path] = await n.enqueue(
          url: parts[i].url,
          path: path,
          title: '${model.name} (${i + 1}/${parts.length})',
        );
      }
      onProgress(0, total);
      while (true) {
        if (cancel.isCancelled) throw const DownloadCancelled();
        final now = {for (final d in await n.list()) d.id: d};
        var received = 0;
        var done = true;
        for (final id in ids.values) {
          final d = now[id];
          // Gone means the user removed it from the system's download list.
          if (d == null) throw const DownloadCancelled();
          if (d.status == NativeDownloadStatus.failed) throw NativeDownloadFailed(d.reason);
          if (d.status != NativeDownloadStatus.done) done = false;
          received += d.received;
        }
        if (done) break;
        onProgress(total == null ? received : received.clamp(0, total), total);
        await Future.any([Future<void>.delayed(poll), cancel.whenCancelled]);
      }
      // All bytes are in: what is left is the check.
      onProgress(total ?? 0, total);
      for (final p in parts) {
        if (cancel.isCancelled) throw const DownloadCancelled();
        final ok = await n.adopt(
          path: rel(p),
          dest: '$staging/${p.path}',
          sha256: p.sha256,
          size: p.sizeBytes,
        );
        if (!ok) throw const ChecksumMismatch();
      }
    } finally {
      await n.remove(ids.values.toList());
    }
  }

  /// Without a system downloader: each file straight into [staging], hashed
  /// as it arrives.
  Future<void> _downloadParts(
    VoiceModel model,
    String staging,
    DownloadProgress onProgress,
    DownloadCancel cancel,
  ) async {
    final total = model.sizeBytes;
    var before = 0;
    onProgress(0, total);
    for (final p in model.parts) {
      final file = File('$staging/${p.path}');
      await file.parent.create(recursive: true);
      await _fetch(
        Uri.parse(p.url),
        file.path,
        size: p.sizeBytes,
        sha: p.sha256,
        onProgress: (r, _) => onProgress(before + r, total),
        cancel: cancel,
      );
      before += p.sizeBytes;
      if (cancel.isCancelled) throw const DownloadCancelled();
    }
  }

  Future<VoiceModel> _downloadArchive(
    VoiceModel model,
    String dir,
    DownloadProgress onProgress,
    DownloadCancel cancel,
  ) async {
    final id = model.id;
    final part = '$dir/$id.part';
    final staging = '$dir/$id.extracting';
    final target = '$dir/$id';
    try {
      await _remove(part);
      await _remove(staging);
      await _fetch(
        Uri.parse(model.url),
        part,
        size: model.sizeBytes,
        sha: model.sha256,
        onProgress: onProgress,
        cancel: cancel,
      );
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

  /// Streams [uri] into [path], hashing as it goes; throws [ChecksumMismatch]
  /// when the size ([size], if known) or SHA-256 differs.
  Future<void> _fetch(
    Uri uri,
    String path, {
    required int? size,
    required String sha,
    required DownloadProgress onProgress,
    required DownloadCancel cancel,
  }) async {
    final client = _client();
    final sink = File(path).openWrite();
    final digest = _DigestSink();
    final hasher = sha256.startChunkedConversion(digest);
    final limit = size ?? _maxUnpinnedBytes;
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
      final total = size ?? res.contentLength;
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
      if ((size != null && received != size) || digest.value.toString() != sha) {
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
