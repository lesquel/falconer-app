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

  /// Fetches, verifies and unpacks [model]; returns it with its file paths.
  /// Throws [DownloadCancelled] when [cancel] fires; nothing usable is left
  /// behind on any failure.
  Future<VoiceModel> download(
    VoiceModel model, {
    required DownloadProgress onProgress,
    required DownloadCancel cancel,
  });

  /// Frees the disk space of [id].
  Future<void> delete(String id);

  /// Absolute folder of an installed model.
  Future<String> folderOf(String id);
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

/// The server answered with something other than 200.
final class DownloadHttpFailure implements Exception {
  const DownloadHttpFailure(this.status);
  final int status;
}
