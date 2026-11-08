/// UnifiedPush (no Google services). Works in the foreground engine and in
/// the background engine the connector starts with `--unifiedpush-bg`.
library;

import 'dart:async';

import 'package:unifiedpush_platform_interface/unifiedpush_platform_interface.dart';

import '../../../../shared/domain/failure.dart';
import '../../../../shared/logging/redacting_logger.dart';
import '../../domain/repositories/inbox_ports.dart';

typedef EndpointStore = ({Future<String?> Function() read, Future<void> Function(String) write});
typedef MessageHandler = Future<void> Function(List<int> body);

class UnifiedPushDatasource implements PushEndpointSource {
  UnifiedPushDatasource(this._store);

  static const instance = 'openmosh';
  final EndpointStore _store;
  Completer<String>? _waiting;
  MessageHandler? _onMessage;

  UnifiedPushPlatform get _up => UnifiedPushPlatform.instance;

  Future<void> initialize({required MessageHandler onMessage}) async {
    _onMessage = onMessage;
    await _up.initializeCallback(
      onNewEndpoint: (e, _) async {
        await _store.write(e.url);
        Log.info('push', 'new endpoint registered');
        final w = _waiting;
        if (w != null && !w.isCompleted) w.complete(e.url);
      },
      onRegistrationFailed: (reason, _) {
        final w = _waiting;
        if (w != null && !w.isCompleted) {
          w.completeError(const PushFailure('The push distributor refused the registration.'));
        }
      },
      onUnregistered: (_) {},
      onMessage: (m, _) async {
        try {
          await _onMessage?.call(m.content);
        } catch (e) {
          Log.error('push', 'message handling failed', e);
        }
      },
    );
  }

  @override
  Future<String?> knownEndpoint() => _store.read();

  @override
  Future<String> currentEndpoint() async {
    final known = await _store.read();
    if (known != null) return known;
    if (!await _up.tryUseCurrentOrDefaultDistributor()) {
      final ds = await _up.getDistributors(const []);
      if (ds.isEmpty) {
        throw const PushFailure(
          'No UnifiedPush distributor found. Install ntfy (F-Droid or GitHub) and try again.',
        );
      }
      await _up.saveDistributor(ds.first);
    }
    final w = _waiting = Completer<String>();
    await _up.register(instance, const [], 'OpenMosh agent notifications', null);
    try {
      return await w.future.timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const PushFailure('The push distributor did not answer. Open ntfy and retry.');
    } finally {
      _waiting = null;
    }
  }
}
