import Flutter
import UIKit

/// `dev.openmosh/clipboard` on iOS.
///
/// The copy is `localOnly` so Universal Clipboard never syncs it to other
/// devices, and it expires on its own after [lifetime] (Android has no
/// expiry; the Dart side clears explicitly where it matters).
enum SecureClipboard {
  static let lifetime: TimeInterval = 120

  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "dev.openmosh/clipboard", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        switch call.method {
        case "setSensitive":
          let text = (call.arguments as? [String: Any])?["text"] as? String ?? ""
          UIPasteboard.general.setItems(
            [["public.utf8-plain-text": text]],
            options: [
              .localOnly: true,
              .expirationDate: Date(timeIntervalSinceNow: lifetime),
            ])
          result(nil)
        case "clear":
          UIPasteboard.general.items = []
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }
}
