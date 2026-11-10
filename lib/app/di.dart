/// Composition root: the only place that knows concrete adapters.
/// Platform-bound pieces (database, push, notifications) are created in
/// `main.dart` and injected with overrides; tests override the rest.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../features/hosts/data/repositories/drift_host_repository.dart';
import '../features/hosts/domain/entities/host.dart';
import '../features/hosts/domain/repositories/host_repository.dart';
import '../features/hosts/domain/usecases/host_connections.dart';
import '../features/hosts/domain/usecases/manage_hosts.dart';
import '../features/hosts/domain/usecases/paired_devices.dart';
import '../features/inbox/data/repositories/drift_inbox_repository.dart';
import '../features/inbox/data/repositories/drift_sync_cursor_store.dart';
import '../features/inbox/domain/entities/inbox_event.dart';
import '../features/inbox/domain/repositories/inbox_ports.dart';
import '../features/inbox/domain/usecases/inbox_usecases.dart';
import '../features/keys/data/datasources/keys_bridge.dart';
import '../features/keys/data/datasources/local_auth_authenticator.dart';
import '../features/keys/data/datasources/secure_key_storage.dart';
import '../features/keys/data/repositories/secure_key_vault.dart';
import '../features/keys/domain/entities/ssh_key_info.dart';
import '../features/keys/domain/repositories/key_vault.dart';
import '../features/keys/domain/usecases/legacy_key_migration.dart';
import '../features/keys/data/datasources/key_file_picker.dart';
import '../features/lock/domain/app_lock.dart';
import '../features/lock/domain/user_presence.dart';
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
import '../features/voice/data/datasources/channel_native_downloader.dart';
import '../features/voice/data/datasources/record_voice_recorder.dart';
import '../features/voice/data/datasources/sherpa_speech_recognizer.dart';
import '../features/voice/data/repositories/file_model_store.dart';
import '../features/voice/domain/repositories/voice_ports.dart';
import '../shared/data/secure_clipboard.dart';
import '../shared/domain/monotonic.dart';
import '../shared/data/app_database.dart';
import '../features/usage/domain/usecases/load_agent_usage.dart';
import '../shared/hook/domain/hook_client.dart';
import '../shared/ssh/data/datasources/ssh_bridge.dart';
import '../shared/ssh/domain/ssh_ports.dart';
import '../features/terminal/presentation/controllers/terminal_session.dart';
import '../features/terminal/presentation/controllers/terminal_lifecycle.dart';
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

/// The bare prompt. The key vault uses it for its own legacy unlock path, so
/// the migrating wrapper below never re-enters the vault mid-unlock.
final platformAuthenticatorProvider = Provider<UserAuthenticator>(
  (ref) => LocalAuthAuthenticator(),
);
final sshConnectorProvider = Provider<SshConnector>((ref) => const RustSshConnector());
final pairingGatewayProvider = Provider<PairingGateway>((ref) => const TcpPairingGateway());
final fileSourceProvider = Provider<FileSource>((ref) => const FilePickerSource());

final keyVaultProvider = Provider<KeyVault>(
  (ref) => SecureKeyVault(
    ref.watch(databaseProvider),
    ref.watch(secureStorageProvider),
    const KeysBridge(),
    ref.watch(platformAuthenticatorProvider),
    newId: newId,
  ),
);
final legacyKeyMigrationProvider = Provider<MigratingAuthenticator>(
  (ref) =>
      MigratingAuthenticator(ref.watch(platformAuthenticatorProvider), ref.watch(keyVaultProvider)),
);

/// Clipboard for keys and terminal copies (sensitive, cleared for real).
final secureClipboardProvider = Provider<SecureClipboard>((ref) => const SecureClipboard());

/// System file picker for private key files.
final keyFilePickerProvider = Provider<KeyFilePicker>((ref) => const KeyFilePicker());

/// Monotonic time for security windows.
final monotonicClockProvider = Provider<Elapsed>((ref) => bootClock());

/// Remembers the last successful verification (re-verify pooled terminals).
final userPresenceProvider = Provider<UserPresence>(
  (ref) => UserPresence(
    inner: ref.watch(legacyKeyMigrationProvider),
    elapsed: ref.watch(monotonicClockProvider),
  ),
);

/// User verification for sensitive actions; also moves v0.1 keys once.
final authenticatorProvider = Provider<UserAuthenticator>((ref) => ref.watch(userPresenceProvider));

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
    onVerified: ref.watch(userPresenceProvider).markVerified,
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

final enablePushProvider = Provider<EnablePush>(
  (ref) => EnablePush(
    connections: ref.watch(hostConnectionsProvider),
    hosts: ref.watch(hostRepositoryProvider),
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
    cursors: DriftSyncCursorStore(ref.watch(databaseProvider)),
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

final loadAgentUsageProvider = Provider<LoadAgentUsage>(
  (ref) => LoadAgentUsage(ref.watch(hostConnectionsProvider)),
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

/// Background policy for terminals: no retries, close after 10 minutes.
final terminalLifecycleProvider = Provider<TerminalLifecycle>(
  (ref) => TerminalLifecycle(
    pool: ref.watch(terminalSessionPoolProvider),
    disconnectAll: ref.watch(hostConnectionsProvider).disconnectAll,
  ),
);

/// One lock for the app's lifetime.
final appLockProvider = Provider<AppLock>(
  (ref) =>
      AppLock(auth: ref.watch(authenticatorProvider), elapsed: ref.watch(monotonicClockProvider)),
);

final settingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// Downloaded speech models, under the app's private support directory. On
/// Android the catalog files come through the system DownloadManager.
final modelStoreProvider = Provider<ModelStore>(
  (ref) => FileModelStore(
    root: () async => Directory('${(await getApplicationSupportDirectory()).path}/voice_models'),
    native: Platform.isAndroid ? const ChannelNativeDownloader() : null,
  ),
);

/// Microphone for dictation; created only while recording.
final voiceRecorderProvider = Provider<VoiceRecorder>((ref) => RecordVoiceRecorder());

/// On-device speech to text; loads a model on first use, frees it when idle.
final speechRecognizerProvider = Provider<SpeechRecognizer>((ref) {
  final r = SherpaSpeechRecognizer();
  ref.onDispose(() => unawaited(r.release()));
  return r;
});
