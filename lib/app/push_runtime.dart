/// Push pipeline shared by the UI engine and the background engine that
/// UnifiedPush starts with `--unifiedpush-bg` (no Rust, no UI needed).
library;

import '../features/hosts/data/repositories/drift_host_repository.dart';
import '../features/inbox/data/datasources/local_notifications.dart';
import '../features/inbox/data/datasources/unifiedpush_datasource.dart';
import '../features/inbox/data/models/notification_tag.dart';
import '../features/inbox/data/models/push_crypto.dart';
import '../features/inbox/data/repositories/crypto_push_opener.dart';
import '../features/inbox/data/repositories/drift_inbox_repository.dart';
import '../features/inbox/domain/usecases/inbox_usecases.dart';
import '../features/keys/data/datasources/secure_key_storage.dart';
import '../features/keys/data/repositories/secure_key_vault.dart';
import '../features/settings/data/repositories/drift_settings_repository.dart';
import '../shared/data/app_database.dart';
import '../shared/domain/once.dart';

final class PushRuntime {
  PushRuntime._(this.db, this.storage, this.notifier, this.endpoints);

  final AppDatabase db;
  final SecureKeyStorage storage;
  final LocalEventNotifier notifier;
  final UnifiedPushDatasource endpoints;

  static const _endpointKey = 'unifiedpush_endpoint';

  static Future<PushRuntime> start({NotificationTap? onTap}) async {
    final db = AppDatabase.open();
    final storage = SecureKeyStorage();
    // Both engines load the same per-install key from the push namespace,
    // so a tap verifies what the background engine posted.
    final tagger = await NotificationTagger.load(storage);
    final notifier = LocalEventNotifier(
      await LocalEventNotifier.init(tagger, onTap: onTap),
      tagger,
    );
    final endpoints = UnifiedPushDatasource((
      read: () => storage.readPush(_endpointKey),
      write: (v) => storage.writePush(_endpointKey, v),
    ));
    final settings = DriftSettingsRepository(db);
    final hosts = DriftHostRepository(db);
    final inbox = DriftInboxRepository(db);
    final opener = CryptoPushOpener(SecurePushKeyStore(storage));
    await endpoints.initialize(
      onMessage: (body) async {
        // Settings are read at most once per message, and only when needed.
        final current = once(settings.load);
        await HandlePushMessage(
          hosts: hosts,
          inbox: inbox,
          opener: opener,
          notifier: notifier,
          previews: () async => (await current()).notificationPreviews,
          allowed: (hostId, at) async => (await current()).notificationsAllowed(hostId, at),
          kidOf: PushCrypto.kidOf,
          now: DateTime.now,
        )(body);
      },
    );
    return PushRuntime._(db, storage, notifier, endpoints);
  }
}
