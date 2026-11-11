import 'dart:io';

import 'package:openmosh/features/uploads/domain/repositories/file_source.dart';

/// The picker returns one small text file, `notes.txt` (a cache copy).
class OneFileSource implements FileSource {
  int discarded = 0;

  @override
  Future<PickedFile?> pick({required bool imagesOnly}) async {
    final dir = Directory.systemTemp.createTempSync('omtest-pick');
    final f = File('${dir.path}/notes.txt')..writeAsStringSync('hello');
    return PickedFile(path: f.path, name: 'notes.txt', size: 5, temporary: true);
  }

  @override
  Future<List<PickedFile>> pickImages() async => const [];

  @override
  Future<void> discard(PickedFile file) async {
    discarded++;
    File(file.path).parent.deleteSync(recursive: true);
  }
}
