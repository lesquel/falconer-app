import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../domain/entities/webpush_delivery.dart';
import '../../domain/entities/webpush_registration.dart';

final class WebPushState {
  const WebPushState({this.registration, this.deliveries = const {}, this.busy = false});
  final WebPushRegistration? registration;
  final Map<String, WebPushDelivery> deliveries;
  final bool busy;

  /// How the current registration stands on a host.
  WebPushHostStatus statusOf(String hostId) {
    final r = registration;
    final d = deliveries[hostId];
    if (r == null || d == null || d.hash != r.hash) return WebPushHostStatus.pending;
    return switch (d.status) {
      WebPushDeliveryStatus.delivered => WebPushHostStatus.delivered,
      WebPushDeliveryStatus.hookTooOld => WebPushHostStatus.hookTooOld,
      WebPushDeliveryStatus.clearPending => WebPushHostStatus.pending,
    };
  }
}

enum WebPushHostStatus { delivered, pending, hookTooOld }

class WebPushController extends Notifier<WebPushState> {
  @override
  WebPushState build() {
    Future.microtask(reload);
    return const WebPushState();
  }

  Future<void> reload() async {
    final store = ref.read(webPushStoreProvider);
    final reg = await store.registration();
    final del = await store.deliveries();
    state = WebPushState(registration: reg, deliveries: del, busy: state.busy);
  }

  /// Parses a code; throws [WebPushCodeFailure].
  WebPushRegistration inspect(String raw) => ref.read(webPushSyncProvider).inspect(raw);

  /// Stores [r] and forwards it to every paired host.
  Future<Map<String, WebPushHostResult>> activate(WebPushRegistration r) async {
    state = WebPushState(
      registration: state.registration,
      deliveries: state.deliveries,
      busy: true,
    );
    try {
      final sync = ref.read(webPushSyncProvider);
      await sync.activate(r);
      return await sync.syncAll(ref.read(hostConnectionsProvider).runHook);
    } finally {
      state = const WebPushState();
      await reload();
    }
  }

  Future<void> turnOff() async {
    state = WebPushState(
      registration: state.registration,
      deliveries: state.deliveries,
      busy: true,
    );
    try {
      await ref.read(webPushSyncProvider).disable(ref.read(hostConnectionsProvider).runHook);
    } finally {
      state = const WebPushState();
      await reload();
    }
  }
}

final webPushControllerProvider = NotifierProvider<WebPushController, WebPushState>(
  WebPushController.new,
);
