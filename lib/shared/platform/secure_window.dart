/// FLAG_SECURE control (T-5): blocks screenshots, screen recording and the
/// recents thumbnail while a sensitive screen is visible.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

abstract final class SecureWindow {
  static const _channel = MethodChannel('dev.openmosh/secure_window');
  static int _holders = 0;

  static Future<void> acquire() async {
    _holders++;
    if (_holders == 1) await _set(true);
  }

  static Future<void> release() async {
    if (_holders == 0) return;
    _holders--;
    if (_holders == 0) await _set(false);
  }

  static Future<void> _set(bool on) async {
    try {
      await _channel.invokeMethod<void>('setSecure', on);
    } on MissingPluginException {
      // tests / non-Android
    }
  }
}

/// Wrap terminal, keys and pairing screens with this widget.
class SecureScreen extends StatefulWidget {
  const SecureScreen({super.key, required this.child});
  final Widget child;

  @override
  State<SecureScreen> createState() => _SecureScreenState();
}

class _SecureScreenState extends State<SecureScreen> {
  @override
  void initState() {
    super.initState();
    SecureWindow.acquire();
  }

  @override
  void dispose() {
    SecureWindow.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
