import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../domain/repositories/voice_ports.dart';

/// Upper bound on what one model may unpack to (the largest catalog model is
/// about 1 GB unpacked).
const maxUnpackedBytes = 4 << 30;

/// `/`-separated relative path of a tar entry, or [UnsafeArchive] when it is
/// absolute or climbs out with `..`.
String _safeRelative(String name) {
  final n = name.replaceAll('\\', '/');
  if (n.startsWith('/') || RegExp(r'^[A-Za-z]:').hasMatch(n)) throw UnsafeArchive(name);
  final parts = [
    for (final s in n.split('/'))
      if (s.isNotEmpty && s != '.') s,
  ];
  if (parts.isEmpty || parts.contains('..')) throw UnsafeArchive(name);
  return parts.join('/');
}

/// Unpacks the `.tar.bz2` at [archivePath] into [targetDir], streaming (the
/// archive is never held in memory). Links are refused, as are absolute and
/// `..` paths; other special entries (devices, pipes) are not created as
/// such. With [keep], only those relative paths are written. Writing stops
/// with [UnsafeArchive] once the written files would pass [maxBytes], so a
/// small archive cannot fill the disk.
///
/// Synchronous: run it in an isolate. Returns the relative paths written.
List<String> extractTarBz2(
  String archivePath,
  String targetDir, {
  Set<String>? keep,
  int maxBytes = maxUnpackedBytes,
}) {
  final root = p.normalize(p.absolute(targetDir));
  Directory(root).createSync(recursive: true);
  final written = <String>[];
  var total = 0;
  final input = InputFileStream(archivePath);
  try {
    TarDecoder().decodeStream(
      BZip2Decoder().decodeLazy(input, verify: true),
      verify: true,
      keepEntries: false,
      callback: (entry) {
        if (entry.isSymbolicLink || entry.isHardLink) throw UnsafeArchive(entry.name);
        final rel = _safeRelative(entry.name);
        final dest = p.normalize(p.join(root, rel));
        if (!p.isWithin(root, dest)) throw UnsafeArchive(entry.name);
        if (!entry.isFile) return;
        if (keep != null && !keep.contains(rel)) return;
        total += entry.size;
        if (total > maxBytes) throw UnsafeArchive('${entry.name} (over the size limit)');
        Directory(p.dirname(dest)).createSync(recursive: true);
        final out = OutputFileStream(dest);
        try {
          entry.writeContent(out);
        } finally {
          out.closeSync();
        }
        written.add(rel);
      },
    );
  } finally {
    input.closeSync();
  }
  return written;
}
