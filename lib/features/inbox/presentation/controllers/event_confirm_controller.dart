import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../../../shared/domain/failure.dart';
import '../../domain/entities/inbox_event.dart';

typedef EventKey = ({String hostId, String eventId});

final class ConfirmState {
  const ConfirmState({this.busy = false, this.error});
  final bool busy;
  final String? error;
}

class EventConfirmController extends Notifier<ConfirmState> {
  EventConfirmController(this.key);
  final EventKey key;

  @override
  ConfirmState build() => const ConfirmState();

  /// Every answer is preceded by exactly one user verification: either
  /// here (connection already open) or by the key vault when a new SSH
  /// connection must be opened. [reason] is shown in the verification prompt.
  Future<bool> answer(
    ResponseKind kind, {
    String? text,
    String reason = 'Confirm your answer to the agent',
  }) async {
    state = const ConfirmState(busy: true);
    try {
      if (ref.read(hostConnectionsProvider).isConnected(key.hostId)) {
        final ok = await ref.read(authenticatorProvider).authenticate(reason);
        if (!ok) throw const UserCancelledFailure();
      }
      await ref.read(respondProvider)(key.hostId, key.eventId, kind, text: text);
      state = const ConfirmState();
      return true;
    } on AppFailure catch (e) {
      state = ConfirmState(error: e.message);
      return false;
    } on InvalidTransition {
      state = const ConfirmState(error: 'This event was already answered.');
      return false;
    }
  }
}

final eventConfirmProvider = NotifierProvider.autoDispose
    .family<EventConfirmController, ConfirmState, EventKey>(EventConfirmController.new);
