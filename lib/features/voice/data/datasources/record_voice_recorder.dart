import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../domain/repositories/voice_ports.dart';

/// 16 kHz mono PCM16 from the `record` plugin, kept in memory: nothing is
/// written to storage. The platform recorder exists only while recording.
class RecordVoiceRecorder implements VoiceRecorder {
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _sub;
  BytesBuilder _pcm = BytesBuilder(copy: false);

  static const _config = RecordConfig(
    encoder: AudioEncoder.pcm16bits,
    sampleRate: 16000,
    numChannels: 1,
    androidConfig: AndroidRecordConfig(
      audioSource: AndroidAudioSource.voiceRecognition,
      manageBluetooth: false,
    ),
  );

  @override
  Future<bool> requestPermission() async {
    final r = AudioRecorder();
    try {
      return await r.hasPermission();
    } finally {
      await r.dispose();
    }
  }

  @override
  Future<void> start() async {
    await cancel();
    final r = _recorder = AudioRecorder();
    _pcm = BytesBuilder(copy: false);
    final stream = await r.startStream(_config);
    _sub = stream.listen(_pcm.add);
  }

  @override
  Future<Float32List> stop() async {
    await _recorder?.stop();
    final bytes = _pcm.takeBytes();
    await _close();
    return pcm16ToFloat32(bytes);
  }

  @override
  Future<void> cancel() async {
    await _recorder?.cancel();
    _pcm.clear();
    await _close();
  }

  Future<void> _close() async {
    await _sub?.cancel();
    _sub = null;
    await _recorder?.dispose();
    _recorder = null;
  }
}

/// Little-endian signed 16-bit samples to floats in [-1, 1].
Float32List pcm16ToFloat32(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final out = Float32List(bytes.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
  }
  return out;
}
