import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../shared/domain/failure.dart';
import '../../domain/entities/upload_name.dart';
import '../../domain/repositories/file_source.dart';

/// System picker. Content URIs are copied into the app cache (capped at the
/// upload limit) so the Rust core can stream them; [PickedFile.temporary]
/// marks copies the caller deletes after upload.
class FilePickerSource implements FileSource {
  const FilePickerSource();

  @override
  Future<PickedFile?> pick({required bool imagesOnly}) async {
    final files = await FilePicker.pickFiles(type: imagesOnly ? FileType.image : FileType.any);
    if (files.isEmpty) return null;
    final f = files.first;
    final size = await f.length() ?? -1;
    checkUploadSize(size);
    final direct = f.path;
    if (direct != null) return PickedFile(path: direct, name: f.name, size: size);

    final dir = await Directory('${(await getTemporaryDirectory()).path}/uploads')
        .create(recursive: true);
    final tmp = File('${dir.path}/${randomUploadPrefix()}');
    final sink = tmp.openWrite();
    var copied = 0;
    try {
      await for (final chunk in f.readAsByteStream()) {
        copied += chunk.length;
        if (copied > maxUploadBytes) throw const ValidationFailure('Files are limited to 50 MB.');
        sink.add(chunk);
      }
    } catch (_) {
      await sink.close();
      await tmp.delete();
      rethrow;
    }
    await sink.close();
    return PickedFile(path: tmp.path, name: f.name, size: copied, temporary: true);
  }

  @override
  Future<void> discard(PickedFile file) async {
    if (!file.temporary) return;
    final f = File(file.path);
    if (await f.exists()) await f.delete();
  }
}
