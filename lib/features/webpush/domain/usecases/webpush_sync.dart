/// Forwards the Web Push registration to every paired host with
/// `devices set-webpush` (JSON on stdin) and tracks, per host, whether the
/// current registration was delivered.
library;

import '../../../../shared/domain/failure.dart';
import '../../../../shared/hook/domain/hook_command.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../../hosts/domain/entities/host.dart';
import '../../../hosts/domain/repositories/host_repository.dart';
import '../entities/webpush_delivery.dart';
import '../entities/webpush_registration.dart';
import '../repositories/webpush_store.dart';

/// Runs one hook command on a connected host.
typedef HookRunner = Future<Object?> Function(HookCommand cmd, {List<int>? stdin});

/// Runs a hook command on the host with this id, connecting if needed.
typedef HostHookRunner = Future<Object?> Function(
  String hostId,
  HookCommand cmd, {
  List<int>? stdin,
});

/// Error codes an `openmosh-hook` without `set-webpush` can answer with.
const _unknownCommandCodes = {'unknown_command', 'unknown', 'usage', 'protocol', 'invalid_args'};

bool _hookTooOld(Object e) => e is HookFailure && _unknownCommandCodes.contains(e.code);

final class WebPushSync {
  const WebPushSync({required this.store, required this.hosts});

  final WebPushStore store;
  final HostRepository hosts;

  /// Validates a code without side effects.
  WebPushRegistration inspect(String raw) => WebPushRegistration.parse(raw);

  /// Makes [r] the current registration; hosts holding another hash get it
  /// on the next [syncAll] or connect.
  ///
  /// Forgets every delivery record, so even an identical code is sent again:
  /// the hook marks a subscription stale after a 404/410 and only a new
  /// `set-webpush` clears that flag.
  Future<void> activate(WebPushRegistration r) async {
    await store.saveRegistration(r);
    await store.clearDeliveries();
  }

  /// Post-connect step (like `SyncPushEndpoint`): delivers the current
  /// registration, or finishes a pending removal. Throws on other failures.
  Future<WebPushHostResult> syncHost(Host host, HookRunner run) async {
    final deviceId = host.deviceId;
    if (deviceId == null) return WebPushHostResult.skipped;
    final reg = await store.registration();
    final current = (await store.deliveries())[host.id];
    if (reg == null) {
      if (current?.status != WebPushDeliveryStatus.clearPending) return WebPushHostResult.skipped;
      return _clear(host.id, deviceId, run);
    }
    if (current?.status == WebPushDeliveryStatus.delivered && current?.hash == reg.hash) {
      return WebPushHostResult.alreadyDelivered;
    }
    try {
      await run(HookCommand.setWebPush(deviceId), stdin: reg.toStdin());
    } catch (e) {
      if (!_hookTooOld(e)) rethrow;
      await store.setDelivery(host.id, WebPushDelivery(WebPushDeliveryStatus.hookTooOld, reg.hash));
      return WebPushHostResult.hookTooOld;
    }
    await store.setDelivery(host.id, WebPushDelivery(WebPushDeliveryStatus.delivered, reg.hash));
    return WebPushHostResult.delivered;
  }

  /// Syncs every paired host one after another (each connection may ask for
  /// the user's verification). A host that cannot be reached stays pending.
  Future<Map<String, WebPushHostResult>> syncAll(HostHookRunner runHook) async {
    final out = <String, WebPushHostResult>{};
    for (final h in await hosts.all()) {
      if (!h.paired) continue;
      out[h.id] = await _guarded(h, runHook);
    }
    return out;
  }

  /// "Turn off": forgets the registration and runs `clear-webpush` on the
  /// hosts that hold it. Unreachable hosts keep a pending removal.
  Future<Map<String, WebPushHostResult>> disable(HostHookRunner runHook) async {
    await store.clearRegistration();
    final out = <String, WebPushHostResult>{};
    final owed = await store.deliveries();
    for (final h in await hosts.all()) {
      final d = owed[h.id];
      if (d == null || !h.paired) continue;
      if (d.status == WebPushDeliveryStatus.hookTooOld) {
        await store.setDelivery(h.id, null); // nothing to clear on an old hook
        continue;
      }
      await store.setDelivery(h.id, WebPushDelivery(WebPushDeliveryStatus.clearPending, d.hash));
      out[h.id] = await _guarded(h, runHook);
    }
    return out;
  }

  Future<WebPushHostResult> _guarded(Host h, HostHookRunner runHook) async {
    try {
      return await syncHost(h, (cmd, {stdin}) => runHook(h.id, cmd, stdin: stdin));
    } on AppFailure catch (e) {
      Log.error('webpush', 'sync failed host=${h.id}', e);
      return WebPushHostResult.failed;
    }
  }

  Future<WebPushHostResult> _clear(String hostId, String deviceId, HookRunner run) async {
    try {
      await run(HookCommand.clearWebPush(deviceId));
    } catch (e) {
      // `not_found`: the host holds nothing for this device. Old hook: nothing to clear.
      if (!_hookTooOld(e) && !(e is HookFailure && e.code == 'not_found')) rethrow;
    }
    await store.setDelivery(hostId, null);
    return WebPushHostResult.cleared;
  }
}
