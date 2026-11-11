import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private let downloads = ModelDownloads()

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let messenger = flutterViewController.engine.binaryMessenger
    BootClock.register(messenger: messenger)
    SecureClipboard.register(messenger: messenger)
    downloads.register(messenger: messenger)

    // Keeps the window out of screenshots, screen sharing and recordings
    // (macOS counterpart of Android's FLAG_SECURE).
    self.sharingType = .none

    super.awakeFromNib()
  }
}
