import 'dart:typed_data';

/// A file already uploaded to the host, waiting in the chat composer.
final class ChatAttachment {
  const ChatAttachment({required this.remotePath, required this.name, this.preview});

  /// Path on the host, ready to paste (quoted only when it needs it).
  final String remotePath;
  final String name;

  /// Image bytes for the thumbnail; null for other files.
  final Uint8List? preview;
}
