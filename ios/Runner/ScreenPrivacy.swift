import UIKit

/// iOS cannot block screenshots or recording, so the only protection is to
/// keep app content out of the app switcher snapshot: a cover goes over every
/// window while its scene is inactive and comes off when it is active again.
/// (Android equivalent: FLAG_SECURE, which also blocks screenshots.)
final class ScreenPrivacy {
  static let shared = ScreenPrivacy()

  private var covers: [ObjectIdentifier: UIView] = [:]
  private var started = false

  func start() {
    guard !started else { return }
    started = true
    let nc = NotificationCenter.default
    nc.addObserver(
      self, selector: #selector(hide(_:)), name: UIScene.willDeactivateNotification, object: nil)
    nc.addObserver(
      self, selector: #selector(show(_:)), name: UIScene.didActivateNotification, object: nil)
  }

  @objc private func hide(_ note: Notification) {
    guard let scene = note.object as? UIWindowScene else { return }
    let key = ObjectIdentifier(scene)
    guard covers[key] == nil,
      let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
    else { return }
    let cover = UIView(frame: window.bounds)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.backgroundColor = .systemBackground  // Opaque: a blur would still leak text shapes.
    window.addSubview(cover)
    covers[key] = cover
  }

  @objc private func show(_ note: Notification) {
    guard let scene = note.object as? UIWindowScene else { return }
    covers.removeValue(forKey: ObjectIdentifier(scene))?.removeFromSuperview()
  }
}
