import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../domain/entities/voice_model.dart';
import '../../domain/repositories/voice_ports.dart';
import 'recognizer_config.dart';

/// sherpa-onnx offline recognizer. The model is loaded on the first
/// dictation (in a background isolate), decoding runs in a background
/// isolate too, and the model is freed after [idle] without use.
class SherpaSpeechRecognizer implements SpeechRecognizer {
  SherpaSpeechRecognizer({this.idle = const Duration(minutes: 2)});

  final Duration idle;

  static var _bindings = false;
  sherpa.OfflineRecognizer? _recognizer;
  String? _key;
  Timer? _idleTimer;
  Future<void> _queue = Future.value();

  @override
  Future<String> transcribe(
    Float32List samples, {
    required VoiceModel model,
    required String folder,
    required String language,
  }) {
    final run = _queue.then((_) => _transcribe(samples, model, folder, language));
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<String> _transcribe(
    Float32List samples,
    VoiceModel model,
    String folder,
    String language,
  ) async {
    _idleTimer?.cancel();
    try {
      final config = recognizerConfig(model, folder: folder, language: language);
      final key = '${model.id}|$folder|$language';
      if (_key != key) {
        _free();
        if (!_bindings) {
          sherpa.initBindings();
          _bindings = true;
        }
        _recognizer = await sherpa.OfflineRecognizer.createAsync(config);
        _key = key;
      }
      return (await _decode(_recognizer!.ptr.address, config, samples)).trim();
    } finally {
      _idleTimer = Timer(idle, _free);
    }
  }

  static Future<String> _decode(
    int address,
    sherpa.OfflineRecognizerConfig config,
    Float32List samples,
  ) => Isolate.run(() {
    sherpa.initBindings();
    final r = sherpa.OfflineRecognizer.fromPtr(ptr: Pointer.fromAddress(address), config: config);
    final stream = r.createStream();
    try {
      stream.acceptWaveform(samples: samples, sampleRate: 16000);
      r.decode(stream);
      return r.getResult(stream).text;
    } finally {
      stream.free();
    }
  });

  void _free() {
    _idleTimer?.cancel();
    _recognizer?.free();
    _recognizer = null;
    _key = null;
  }

  @override
  Future<void> release() => _queue = _queue.then((_) => _free());
}
