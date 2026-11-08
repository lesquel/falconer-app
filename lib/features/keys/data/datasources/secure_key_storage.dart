/// Keystore-backed storage (flutter_secure_storage: AES-GCM key wrapped by
/// Android Keystore, StrongBox when the device has it).
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureKeyStorage {
  SecureKeyStorage({FlutterSecureStorage? ssh, FlutterSecureStorage? push})
    : _ssh =
          ssh ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(storageNamespace: 'openmosh_ssh_keys'),
          ),
      _push =
          push ??
          const FlutterSecureStorage(aOptions: AndroidOptions(storageNamespace: 'openmosh_push'));

  final FlutterSecureStorage _ssh;
  final FlutterSecureStorage _push;

  Future<void> writeSshPrivate(String id, String value) => _ssh.write(key: 'ssh:$id', value: value);
  Future<String?> readSshPrivate(String id) => _ssh.read(key: 'ssh:$id');
  Future<void> deleteSshPrivate(String id) => _ssh.delete(key: 'ssh:$id');

  Future<String?> readPush(String name) => _push.read(key: name);
  Future<void> writePush(String name, String value) => _push.write(key: name, value: value);
}
