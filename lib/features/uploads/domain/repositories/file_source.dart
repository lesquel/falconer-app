final class PickedFile {
  const PickedFile({required this.path, required this.name, required this.size});
  final String path;
  final String name;
  final int size;
}

/// System picker for images or any file.
abstract interface class FileSource {
  Future<PickedFile?> pick({required bool imagesOnly});
}
