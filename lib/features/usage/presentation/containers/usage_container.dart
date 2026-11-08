import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/usage_controller.dart';
import '../views/usage_view.dart';

class UsageContainer extends ConsumerStatefulWidget {
  const UsageContainer({super.key, required this.hostId});
  final String hostId;

  @override
  ConsumerState<UsageContainer> createState() => _UsageContainerState();
}

class _UsageContainerState extends ConsumerState<UsageContainer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(ref.read(usageControllerProvider(widget.hostId).notifier).load()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usageControllerProvider(widget.hostId));
    final ctrl = ref.read(usageControllerProvider(widget.hostId).notifier);
    return Scaffold(
      body: UsageView(
        days: state.days,
        report: state.report,
        loading: state.loading,
        error: state.error,
        onDays: (d) => unawaited(ctrl.setDays(d)),
        onRefresh: ctrl.load,
        onBack: () => context.canPop() ? context.pop() : context.go('/hosts/${widget.hostId}'),
      ),
    );
  }
}
