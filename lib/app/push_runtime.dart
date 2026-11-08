/// Push pipeline shared by the UI engine and the background engine that
/// UnifiedPush starts with `--unifiedpush-bg` (no Rust, no UI needed).
library;

import '../features/hosts/data/repositories/drift_host_repository.dart';
import '../features/inbox/data/datasources/local_notifications.dart';
import '../features/inbox/data/datasources/unifiedpush_datasource.dart';
import '../features/inbox/data/models/push_crypto.dart';
import '../features/inbox/data/repositories/crypto_push_opener.dart';
import '../features/inbox/data/repositories/drift_inbox_repository.dart';
import '../features/inbox/domain/usecases/inbox_usecases.dart';
import '../features/keys/data/datasources/secure_key_storage.dart';
import '../features/keys/data/repositories/secure_key_vault.dart';
import '../features/settings/data/repositories/drift_settings_repository.dart';
import '../shared/data/app_database.dart';

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
    final notifier = LocalEventNotifier(await LocalEventNotifier.init(onTap: onTap));
    final endpoints = UnifiedPushDatasource((
      read: () => storage.readPush(_endpointKey),
      write: (v) => storage.writePush(_endpointKey, v),
    ));
    final settings = DriftSettingsRepository(db);
    final handle = HandlePushMessage(
      hosts: DriftHostRepository(db),
      inbox: DriftInboxRepository(db),
      opener: CryptoPushOpener(SecurePushKeyStore(storage)),
      notifier: notifier,
      previews: () async => (await settings.load()).notificationPreviews,
      kidOf: PushCrypto.kidOf,
    );
    await endpoints.initialize(onMessage: (body) async {
      await handle(body);
    });
    return PushRuntime._(db, storage, notifier, endpoints);
  }
}
