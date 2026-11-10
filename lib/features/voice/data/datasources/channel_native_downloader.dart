import 'package:flutter/services.dart';

import '../../domain/repositories/voice_ports.dart';

/// Android DownloadManager behind `dev.openmosh/downloads` (ModelDownloads.kt).
class ChannelNativeDownloader implements NativeDownloader {
  const ChannelNativeDownloader();

  static const _channel = MethodChannel('dev.openmosh/downloads');

  static const _status = {
    'pending': NativeDownloadStatus.pending,
    'running': NativeDownloadStatus.running,
    'paused': NativeDownloadStatus.paused,
    'done': NativeDownloadStatus.done,
  };

  @override
  Future<int> enqueue({required String url, required String path, required String title}) async =>
      (await _channel.invokeMethod<int>('enqueue', {'url': url, 'path': path, 'title': title}))!;

  @override
  Future<List<NativeDownload>> list() async {
    final rows = await _channel.invokeListMethod<Map<Object?, Object?>>('list') ?? const [];
    return [
      for (final r in rows)
        NativeDownload(
          id: r['id']! as int,
          path: r['path']! as String,
          status: _status[r['status']] ?? NativeDownloadStatus.failed,
          received: (r['received'] as int?) ?? 0,
          total: r['total'] as int?,
          reason: (r['reason'] as int?) ?? 0,
        ),
    ];
  }

  @override
  Future<void> remove(List<int> ids) async {
    if (ids.isNotEmpty) await _channel.invokeMethod<void>('remove', {'ids': ids});
  }

  @override
  Future<bool> adopt({
    required String path,
    required String dest,
    required String sha256,
    required int size,
  }) async =>
      await _channel.invokeMethod<bool>('adopt', {
        'path': path,
        'dest': dest,
        'sha256': sha256,
        'size': size,
      }) ??
      false;
}
