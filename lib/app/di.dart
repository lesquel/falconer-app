/// Composition root: the only place that knows concrete adapters.
/// Platform-bound pieces (database, push, notifications) are created in
/// `main.dart` and injected with overrides; tests override the rest.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/hosts/data/repositories/drift_host_repository.dart';
import '../features/hosts/domain/entities/host.dart';
import '../features/hosts/domain/repositories/host_repository.dart';
import '../features/hosts/domain/usecases/host_connections.dart';
import '../features/hosts/domain/usecases/manage_hosts.dart';
import '../features/hosts/domain/usecases/paired_devices.dart';
import '../features/inbox/data/repositories/drift_inbox_repository.dart';
import '../features/inbox/domain/entities/inbox_event.dart';
import '../features/inbox/domain/repositories/inbox_ports.dart';
import '../features/inbox/domain/usecases/inbox_usecases.dart';
import '../features/keys/data/datasources/keys_bridge.dart';
import '../features/keys/data/datasources/local_auth_authenticator.dart';
import '../features/keys/data/datasources/secure_key_storage.dart';
import '../features/keys/data/repositories/secure_key_vault.dart';
import '../features/keys/domain/entities/ssh_key_info.dart';
import '../features/keys/domain/repositories/key_vault.dart';
import '../features/lock/domain/app_lock.dart';
import '../features/pairing/data/repositories/tcp_pairing_gateway.dart';
import '../features/pairing/domain/repositories/pairing_gateway.dart';
import '../features/pairing/domain/usecases/pair_usecases.dart';
import '../features/sessions/domain/usecases/session_catalog.dart';
import '../features/settings/data/repositories/drift_settings_repository.dart';
import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/domain/repositories/settings_repository.dart';
import '../features/uploads/data/datasources/file_picker_source.dart';
import '../features/uploads/domain/repositories/file_source.dart';
import '../features/uploads/domain/usecases/upload_file.dart';
import '../shared/data/app_database.dart';
import '../shared/hook/domain/hook_client.dart';
import '../shared/ssh/data/datasources/ssh_bridge.dart';
import '../shared/ssh/domain/ssh_ports.dart';
import '../features/terminal/presentation/controllers/terminal_session.dart';
import '../features/terminal/presentation/controllers/terminal_session_pool.dart';

String newId() {
  final r = Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

T _mustOverride<T>(String name) => throw UnimplementedError('$name must be overridden in main()');

// Platform-bound, overridden in main().
final databaseProvider = Provider<AppDatabase>((ref) => _mustOverride('databaseProvider'));
final pushEndpointsProvider = Provider<PushEndpointSource>(
  (ref) => _mustOverride('pushEndpointsProvider'),
);
final notifierProvider = Provider<EventNotifier>((ref) => _mustOverride('notifierProvider'));

// Adapters.
final secureStorageProvider = Provider<SecureKeyStorage>((ref) => SecureKeyStorage());
final authenticatorProvider = Provider<UserAuthenticator>((ref) => LocalAuthAuthenticator());
final sshConnectorProvider = Provider<SshConnector>((ref) => const RustSshConnector());
final pairingGatewayProvider = Provider<PairingGateway>((ref) => const TcpPairingGateway());
final fileSourceProvider = Provider<FileSource>((ref) => const FilePickerSource());

final keyVaultProvider = Provider<KeyVault>(
  (ref) => SecureKeyVault(
    ref.watch(databaseProvider),
    ref.watch(secureStorageProvider),
    const KeysBridge(),
    ref.watch(authenticatorProvider),
    newId: newId,
  ),
);
final pushKeysProvider = Provider<PushKeyStore>(
  (ref) => SecurePushKeyStore(ref.watch(secureStorageProvider)),
);
final hostRepositoryProvider = Provider<HostRepository>(
  (ref) => DriftHostRepository(ref.watch(databaseProvider)),
);
final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => DriftInboxRepository(ref.watch(databaseProvider)),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(databaseProvider)),
);

// Use cases.
final hostConnectionsProvider = Provider<HostConnections>((ref) {
  final hosts = ref.watch(hostRepositoryProvider);
  final pool = HostConnections(
    hosts: hosts,
    vault: ref.watch(keyVaultProvider),
    connector: ref.watch(sshConnectorProvider),
  );
  final endpointSync = SyncPushEndpoint(hosts: hosts, endpoints: ref.watch(pushEndpointsProvider));
  const hook = HookClient();
  pool.addOnConnected((host, conn) async {
    var path = host.hookPath;
    if (host.deviceId == null) return;
    if (path == null) {
      path = await hook.resolvePath(conn);
      await hosts.save(host.copyWith(hookPath: path));
    }
    final p = path;
    await endpointSync(host, (cmd) => hook.call(conn, p, cmd));
  });
  ref.onDispose(pool.disconnectAll);
  return pool;
});

final manageHostsProvider = Provider<ManageHosts>(
  (ref) => ManageHosts(
    ref.watch(hostRepositoryProvider),
    ref.watch(sshConnectorProvider),
    newId: newId,
    now: DateTime.now,
  ),
);

final pairWithQrProvider = Provider<PairWithQr>(
  (ref) => PairWithQr(
    gateway: ref.watch(pairingGatewayProvider),
    vault: ref.watch(keyVaultProvider),
    pushKeys: ref.watch(pushKeysProvider),
    endpoints: ref.watch(pushEndpointsProvider),
    hosts: ref.watch(hostRepositoryProvider),
    newId: newId,
    now: DateTime.now,
  ),
);

final pairOverSshProvider = Provider<PairOverSsh>(
  (ref) => PairOverSsh(
    connections: ref.watch(hostConnectionsProvider),
    hosts: ref.watch(hostRepositoryProvider),
    pushKeys: ref.watch(pushKeysProvider),
    endpoints: ref.watch(pushEndpointsProvider),
  ),
);

final respondProvider = Provider<RespondToEvent>(
  (ref) => RespondToEvent(
    inbox: ref.watch(inboxRepositoryProvider),
    connections: ref.watch(hostConnectionsProvider),
    notifier: ref.watch(notifierProvider),
  ),
);

final syncInboxProvider = Provider<SyncInbox>(
  (ref) => SyncInbox(
    inbox: ref.watch(inboxRepositoryProvider),
    connections: ref.watch(hostConnectionsProvider),
  ),
);

final pairedDevicesProvider = Provider<PairedDevices>(
  (ref) => PairedDevices(
    connections: ref.watch(hostConnectionsProvider),
    hosts: ref.watch(hostRepositoryProvider),
    auth: ref.watch(authenticatorProvider),
  ),
);

final sessionCatalogProvider = Provider<SessionCatalog>(
  (ref) => SessionCatalog(ref.watch(hostConnectionsProvider)),
);

final uploadFileProvider = Provider<UploadFile>(
  (ref) => UploadFile(ref.watch(hostConnectionsProvider)),
);

// Streams for the UI.
final hostsProvider = StreamProvider<List<Host>>(
  (ref) => ref.watch(hostRepositoryProvider).watchAll(),
);
final hostProvider = StreamProvider.family<Host?, String>(
  (ref, id) => ref
      .watch(hostRepositoryProvider)
      .watchAll()
      .map((hs) => hs.where((h) => h.id == id).firstOrNull),
);
final inboxProvider = StreamProvider<List<InboxEvent>>(
  (ref) => ref.watch(inboxRepositoryProvider).watchAll(),
);
final keysProvider = StreamProvider<List<SshKeyInfo>>(
  (ref) => ref.watch(keyVaultProvider).watchAll(),
);

/// Terminals kept alive across screens ("Keep sessions connected").
final terminalSessionPoolProvider = Provider<TerminalSessionPool<TerminalSession>>((ref) {
  final pool = TerminalSessionPool<TerminalSession>(close: (s) => s.dispose());
  ref.onDispose(() => unawaited(pool.closeAll()));
  return pool;
});

/// One lock for the app's lifetime.
final appLockProvider = Provider<AppLock>(
  (ref) => AppLock(auth: ref.watch(authenticatorProvider), now: DateTime.now),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);
