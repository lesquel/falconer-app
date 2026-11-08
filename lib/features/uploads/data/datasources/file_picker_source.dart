import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker;
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart'
    show ImagePickerPlatform;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../shared/domain/failure.dart';
import '../../domain/entities/upload_name.dart';
import '../../domain/repositories/file_source.dart';

typedef PickFiles = Future<List<PlatformFile>> Function(FileType type);

Future<List<PlatformFile>> _systemPicker(FileType type) => FilePicker.pickFiles(type: type);

typedef PickImagePaths = Future<List<String>> Function();

/// Android photo picker (the system bottom sheet), never the gallery app.
Future<List<String>> _photoPicker() async {
  final impl = ImagePickerPlatform.instance;
  if (impl is ImagePickerAndroid) impl.useAndroidPhotoPicker = true;
  final files = await ImagePicker().pickMultiImage(requestFullMetadata: false, limit: 10);
  return [for (final f in files) f.path];
}

/// System picker. Content URIs are copied into the app cache (capped at the
/// upload limit) so the Rust core can stream them. Any picked file that lives
/// in the app cache (our copies and the copies file_picker itself makes under
/// `cache/file_picker/`) is [PickedFile.temporary] and is deleted by
/// [discard] after the upload, whether it succeeded or failed.
class FilePickerSource implements FileSource {
  const FilePickerSource({
    this.pickFiles = _systemPicker,
    this.pickImagePaths = _photoPicker,
    this.cacheDir = getTemporaryDirectory,
  });

  final PickFiles pickFiles;
  final PickImagePaths pickImagePaths;

  /// The app cache (Android `Context.getCacheDir()`).
  final Future<Directory> Function() cacheDir;

  @override
  Future<PickedFile?> pick({required bool imagesOnly}) async {
    final files = await pickFiles(imagesOnly ? FileType.image : FileType.any);
    if (files.isEmpty) return null;
    final f = files.first;
    final size = await f.length() ?? -1;
    final cache = (await cacheDir()).path;
    final direct = f.path;
    if (direct != null) {
      final picked = PickedFile(
        path: direct,
        name: f.name,
        size: size,
        temporary: _inside(cache, direct),
      );
      try {
        checkUploadSize(size);
      } catch (_) {
        await discard(picked);
        rethrow;
      }
      return picked;
    }
    checkUploadSize(size);

    final dir = await Directory('$cache/uploads').create(recursive: true);
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
  Future<List<PickedFile>> pickImages() async {
    final cache = (await cacheDir()).path;
    final picked = <PickedFile>[];
    for (final path in await pickImagePaths()) {
      final f = File(path);
      picked.add(
        PickedFile(
          path: path,
          name: p.basename(path),
          size: await f.length(),
          temporary: _inside(cache, path),
        ),
      );
    }
    try {
      for (final f in picked) {
        checkUploadSize(f.size);
      }
    } catch (_) {
      for (final f in picked) {
        await discard(f);
      }
      rethrow;
    }
    return picked;
  }

  @override
  Future<void> discard(PickedFile file) async {
    if (!file.temporary) return;
    final cache = (await cacheDir()).path;
    if (!_inside(cache, file.path)) return;
    final f = File(file.path);
    if (await f.exists()) await f.delete();
    // file_picker puts each copy in its own `cache/file_picker/<stamp>/` dir.
    final parent = Directory(p.normalize(p.absolute(f.parent.path)));
    final pickerRoot = p.join(p.normalize(p.absolute(cache)), 'file_picker');
    if (p.isWithin(pickerRoot, parent.path) && await parent.list().isEmpty) {
      await parent.delete();
    }
  }

  static bool _inside(String dir, String path) =>
      p.isWithin(p.normalize(p.absolute(dir)), p.normalize(p.absolute(path)));
}
