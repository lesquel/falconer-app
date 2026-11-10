import 'dart:async';
import 'dart:typed_data';

import '../entities/voice_model.dart';

/// Lets the user stop a running download.
final class DownloadCancel {
  final _done = Completer<void>();

  bool get isCancelled => _done.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _done.future;

  void cancel() {
    if (!_done.isCompleted) _done.complete();
  }
}

/// Bytes received so far; [total] is null when the size is unknown.
typedef DownloadProgress = void Function(int received, int? total);

/// Downloaded models on the device. Only [download] touches the network, and
/// only when the user asks for it.
abstract interface class ModelStore {
  /// Ids of the models whose folders are complete. Never downloads.
  Future<Set<String>> installed();

  /// Ids of models whose download the user started in an earlier run and the
  /// system downloader still holds (running or finished). Leftovers of models
  /// not in [known], or already installed, are removed. Never downloads.
  Future<Set<String>> interrupted(Set<String> known);

  /// Fetches, verifies and installs [model]; returns it with its file paths.
  /// Throws [DownloadCancelled] when [cancel] fires; nothing usable is left
  /// behind on any failure. With [resumeOnly] nothing new is requested: an
  /// [interrupted] download is finished, or cleaned up and cancelled when a
  /// file of it is gone.
  Future<VoiceModel> download(
    VoiceModel model, {
    required DownloadProgress onProgress,
    required DownloadCancel cancel,
    bool resumeOnly = false,
  });

  /// Frees the disk space of [id].
  Future<void> delete(String id);

  /// Absolute folder of an installed model.
  Future<String> folderOf(String id);
}

enum NativeDownloadStatus { pending, running, paused, done, failed }

/// A file held by the system downloader. [path] is relative to its staging
/// area (`<model id>/<file>`).
final class NativeDownload {
  const NativeDownload({
    required this.id,
    required this.path,
    required this.status,
    this.received = 0,
    this.total,
    this.reason = 0,
  });
  final int id;
  final String path;
  final NativeDownloadStatus status;
  final int received;
  final int? total;

  /// Why it failed or is paused, as reported by the system.
  final int reason;
}

/// The phone's download service: keeps going in the background and across
/// network drops, shows a notification, and outlives the app process. Files
/// land in a staging area other apps may read on old Android versions, so
/// nothing there is used before [adopt] checked it.
abstract interface class NativeDownloader {
  /// Starts fetching [url] into the staging [path]; returns its id.
  Future<int> enqueue({required String url, required String path, required String title});

  /// Every download of this app the system still knows about.
  Future<List<NativeDownload>> list();

  /// Stops [ids] and deletes their staging files.
  Future<void> remove(List<int> ids);

  /// Copies the staging [path] to [dest] (private storage) while hashing it;
  /// true only when the size and SHA-256 match, otherwise nothing is left at
  /// [dest].
  Future<bool> adopt({
    required String path,
    required String dest,
    required String sha256,
    required int size,
  });
}

/// Microphone capture at 16 kHz mono, kept in memory only.
abstract interface class VoiceRecorder {
  /// Asks Android for the microphone permission when it is not granted yet.
  Future<bool> requestPermission();
  Future<void> start();

  /// Stops and returns the samples in [-1, 1].
  Future<Float32List> stop();

  /// Stops and drops the audio.
  Future<void> cancel();
}

/// Offline speech to text.
abstract interface class SpeechRecognizer {
  /// [language] is a code from the model's list, or empty for automatic.
  Future<String> transcribe(
    Float32List samples, {
    required VoiceModel model,
    required String folder,
    required String language,
  });

  /// Frees the loaded model, if any.
  Future<void> release();
}

final class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// The archive's SHA-256 (or size) is not the pinned one.
final class ChecksumMismatch implements Exception {
  const ChecksumMismatch();
}

/// The archive holds an absolute path, a `..` segment or a link.
final class UnsafeArchive implements Exception {
  const UnsafeArchive(this.entry);
  final String entry;

  @override
  String toString() => 'Unsafe archive entry: $entry';
}

/// The system downloader gave up on a file.
final class NativeDownloadFailed implements Exception {
  const NativeDownloadFailed(this.reason);
  final int reason;
}

/// The server answered with something other than 200.
final class DownloadHttpFailure implements Exception {
  const DownloadHttpFailure(this.status);
  final int status;
}
