import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../../../shared/domain/failure.dart';
import '../controllers/chat_attachment.dart';

/// Images up to this size get a thumbnail in the composer.
const maxAttachmentPreviewBytes = 12 * 1024 * 1024;

/// The chat composer's attach flow, shared by the terminal and the graphic
/// view: photos or a file, uploaded to the host over SFTP.
///
/// Asks photos or file; null when the sheet was dismissed.
Future<bool?> askAttachmentKind(BuildContext context) {
  final l = context.l10n;
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.attachPhotos),
            onTap: () => Navigator.of(sheet).pop(true),
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: Text(l.attachFile),
            onTap: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    ),
  );
}

/// Picks [images] (or any file) and uploads them to [hostId]; returns them
/// with a thumbnail for images. A failure shows a snack bar and returns
/// none. Picked cache copies are always discarded.
Future<List<ChatAttachment>> uploadAttachments(
  BuildContext context,
  WidgetRef ref,
  String hostId, {
  required bool images,
}) async {
  final source = ref.read(fileSourceProvider);
  final upload = ref.read(uploadFileProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l = context.l10n;
  try {
    final files = images ? await source.pickImages() : [?(await source.pick(imagesOnly: false))];
    final done = <ChatAttachment>[];
    try {
      for (final file in files) {
        final remote = await upload(hostId, file);
        final preview = images && file.size <= maxAttachmentPreviewBytes
            ? await File(file.path).readAsBytes()
            : null;
        done.add(ChatAttachment(remotePath: remote, name: file.name, preview: preview));
      }
    } finally {
      for (final file in files) {
        await source.discard(file);
      }
    }
    return done;
  } on AppFailure catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l.failureMessage(e.message))));
    return const [];
  } on FileSystemException {
    return const [];
  }
}
