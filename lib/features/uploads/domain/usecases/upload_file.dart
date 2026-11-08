import '../../../../shared/domain/posix_shell.dart';
import '../../../hosts/domain/usecases/host_connections.dart';
import '../entities/upload_name.dart';
import '../repositories/file_source.dart';

/// Uploads a picked file over SFTP and returns the text to paste at the
/// cursor: the quoted remote path followed by a space.
final class UploadFile {
  const UploadFile(this.connections, {this.prefix = randomUploadPrefix});

  final HostConnections connections;
  final String Function() prefix;

  Future<String> call(String hostId, PickedFile file) async {
    checkUploadSize(file.size);
    final name = sanitizeUploadName(file.name, prefix: prefix());
    final conn = await connections.connection(hostId);
    final remote = await conn.upload(file.path, name);
    return shQuoteIfNeeded(remote);
  }
}
