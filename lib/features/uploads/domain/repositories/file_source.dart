final class PickedFile {
  const PickedFile({required this.path, required this.name, required this.size, this.temporary = false});
  final String path;
  final String name;
  final int size;

  /// A cache copy that must be deleted after the upload.
  final bool temporary;
}

/// System picker for images or any file.
abstract interface class FileSource {
  Future<PickedFile?> pick({required bool imagesOnly});
  Future<void> discard(PickedFile file);
}
