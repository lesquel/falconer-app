import Cocoa
import FlutterMacOS

/// `dev.openmosh/clipboard` on macOS.
///
/// Clipboard managers that honor the nspasteboard.org convention skip items
/// that carry the `ConcealedType` marker. macOS has no pasteboard expiry.
enum SecureClipboard {
  private static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")

  static func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "dev.openmosh/clipboard", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        let pb = NSPasteboard.general
        switch call.method {
        case "setSensitive":
          let text = (call.arguments as? [String: Any])?["text"] as? String ?? ""
          pb.clearContents()
          pb.setString(text, forType: .string)
          pb.setData(Data(), forType: concealed)
          result(nil)
        case "clear":
          pb.clearContents()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
  }
}
