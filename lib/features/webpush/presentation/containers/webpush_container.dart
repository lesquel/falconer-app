import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di.dart';
import '../../../../l10n/l10n.dart';
import '../../domain/entities/webpush_registration.dart';
import '../controllers/webpush_controller.dart';
import '../views/webpush_view.dart';

const webPushRoute = '/webpush';

/// A Web Push code pasted or typed in the app. It travels as navigation
/// `extra`, never in a URL, so a link opened from outside cannot fill it.
class WebPushCode {
  const WebPushCode(this.value);
  final String value;
}

/// `/webpush` with a [WebPushCode] extra: shows what the code registers, asks to confirm, then
/// forwards it to every paired host. The code never reaches the log.
class WebPushContainer extends ConsumerStatefulWidget {
  const WebPushContainer({super.key, required this.code});
  final String? code;

  @override
  ConsumerState<WebPushContainer> createState() => _WebPushContainerState();
}

class _WebPushContainerState extends ConsumerState<WebPushContainer> {
  WebPushRegistration? _reg;
  Object? _error;
  List<WebPushHostLine>? _results;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    try {
      _reg = WebPushRegistration.parse(widget.code ?? '');
    } catch (e) {
      _error = e;
    }
  }

  Future<void> _confirm() async {
    final reg = _reg;
    if (reg == null) return;
    setState(() => _busy = true);
    try {
      final out = await ref.read(webPushControllerProvider.notifier).activate(reg);
      final state = ref.read(webPushControllerProvider);
      final hosts = ref.read(hostsProvider).value ?? const [];
      if (!mounted) return;
      setState(() {
        _results = [
          for (final h in hosts)
            if (out.containsKey(h.id)) (alias: h.alias, status: state.statusOf(h.id)),
        ];
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _close() => context.canPop() ? context.pop() : context.go('/settings');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: WebPushView(
        serviceHost: _reg?.serviceHost,
        busy: _busy,
        hosts: _results,
        error: _error == null ? null : l.failureText(_error!),
        onConfirm: _confirm,
        onClose: _close,
      ),
    );
  }
}
