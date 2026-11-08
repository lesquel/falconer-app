/// Reads a private key file chosen in the system file picker.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/domain/failure.dart';

/// OpenSSH ed25519 keys are well under 1 KB; anything bigger is not one.
const maxKeyFileBytes = 16 * 1024;

typedef PickKeyFile = Future<PlatformFile?> Function();

Future<PlatformFile?> _systemPicker() async => (await FilePicker.pickFiles()).firstOrNull;

class KeyFilePicker {
  const KeyFilePicker({this.pick = _systemPicker, this.cacheDir = getTemporaryDirectory});

  final PickKeyFile pick;
  final Future<Directory> Function() cacheDir;

  /// The key text, or null when nothing was chosen. The picker's copy in the
  /// app cache is deleted and the read buffer wiped.
  Future<String?> pickKeyText() async {
    final f = await pick();
    if (f == null) return null;
    final path = f.path;
    Uint8List? bytes;
    try {
      bytes = await _read(f);
      return utf8.decode(bytes);
    } on FormatException {
      throw const ValidationFailure('That is not a usable ssh-ed25519 private key.');
    } finally {
      bytes?.fillRange(0, bytes.length, 0);
      if (path != null && _inside((await cacheDir()).path, path)) {
        try {
          await File(path).delete();
        } on FileSystemException {
          // Already gone.
        }
      }
    }
  }

  static Future<Uint8List> _read(PlatformFile f) async {
    final out = BytesBuilder(copy: false);
    await for (final chunk in f.readAsByteStream()) {
      out.add(chunk);
      if (out.length > maxKeyFileBytes) {
        throw const ValidationFailure('That is not a usable ssh-ed25519 private key.');
      }
    }
    return out.takeBytes();
  }

  static bool _inside(String dir, String path) =>
      File(path).absolute.path.startsWith('${Directory(dir).absolute.path}/');
}
