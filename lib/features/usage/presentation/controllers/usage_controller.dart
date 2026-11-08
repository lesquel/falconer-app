import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/di.dart';
import '../../domain/entities/agent_usage.dart';

final class UsageState {
  const UsageState({this.days = 7, this.report, this.loading = false, this.error});
  final int days;
  final UsageReport? report;
  final bool loading;
  final Object? error;
}

class UsageController extends Notifier<UsageState> {
  UsageController(this.hostId);
  final String hostId;
  var _request = 0;

  @override
  UsageState build() => const UsageState();

  /// Switching the period keeps the previous report on screen until the
  /// new one arrives; a slower earlier reply never overwrites a newer one.
  Future<void> setDays(int days) async {
    if (days == state.days && state.report != null) return;
    state = UsageState(days: days, report: state.report, loading: true);
    await _load();
  }

  Future<void> load() async {
    state = UsageState(days: state.days, report: state.report, loading: true);
    await _load();
  }

  Future<void> _load() async {
    final id = ++_request;
    final days = state.days;
    try {
      final report = await ref.read(loadAgentUsageProvider)(hostId, days: days);
      if (id == _request) state = UsageState(days: days, report: report);
    } catch (e) {
      if (id == _request) state = UsageState(days: days, report: state.report, error: e);
    }
  }
}

final usageControllerProvider = NotifierProvider.autoDispose
    .family<UsageController, UsageState, String>(UsageController.new);
