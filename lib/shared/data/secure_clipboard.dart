/// Clipboard for secrets: copies are marked sensitive (keyboards do not
/// preview them) and clearing removes the clip instead of copying ''.
library;

import 'package:flutter/services.dart';

class SecureClipboard {
  const SecureClipboard([this._channel = const MethodChannel('dev.openmosh/clipboard')]);

  final MethodChannel _channel;

  /// Copies [text] marked as sensitive (Android `EXTRA_IS_SENSITIVE`).
  Future<void> copySensitive(String text) async {
    try {
      await _channel.invokeMethod<void>('setSensitive', {'text': text});
    } on MissingPluginException {
      await Clipboard.setData(ClipboardData(text: text));
    } on PlatformException {
      await Clipboard.setData(ClipboardData(text: text));
    }
  }

  /// Removes whatever is on the clipboard (Android `clearPrimaryClip`).
  Future<void> clear() async {
    try {
      await _channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      await Clipboard.setData(const ClipboardData(text: ''));
    } on PlatformException {
      await Clipboard.setData(const ClipboardData(text: ''));
    }
  }
}
