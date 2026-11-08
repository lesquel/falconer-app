/// Remote file naming and size rules for uploads (T-12).
library;

import 'dart:math';

import '../../../../shared/domain/failure.dart';

const maxUploadBytes = 50 * 1024 * 1024;
const _maxBase = 64;
const _maxExt = 10;

final _unsafeRun = RegExp(r'[^A-Za-z0-9._-]+');
final _leading = RegExp(r'^[._-]+');

/// `<prefix>-<base>[.<ext>]` using only `[A-Za-z0-9._-]`.
String sanitizeUploadName(String original, {required String prefix}) {
  final parts = original.split(RegExp(r'[/\\]'));
  final last = parts.isEmpty ? '' : parts.last;
  final dot = last.lastIndexOf('.');
  var base = dot > 0 ? last.substring(0, dot) : last;
  var ext = dot > 0 ? last.substring(dot + 1) : '';

  base = base.replaceAll(_unsafeRun, '_').replaceFirst(_leading, '');
  if (base.length > _maxBase) base = base.substring(0, _maxBase);
  if (base.isEmpty) base = 'file';

  ext = ext.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toLowerCase();
  if (ext.length > _maxExt) ext = ext.substring(0, _maxExt);

  return ext.isEmpty ? '$prefix-$base' : '$prefix-$base.$ext';
}

String randomUploadPrefix([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(4, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

void checkUploadSize(int bytes) {
  if (bytes < 0) throw const ValidationFailure('Unreadable file size.');
  if (bytes > maxUploadBytes) throw const ValidationFailure('Files are limited to 50 MB.');
}
