import CryptoKit
import Foundation

#if os(iOS)
import Flutter
#else
import FlutterMacOS
#endif

/// `dev.openmosh/downloads`: speech model files through a background
/// `URLSession`, mirroring ModelDownloads.kt (Android DownloadManager).
///
/// - Files land in `<Application Support>/voice_downloads/<path>` (excluded
///   from backup); the Dart side never loads them from there: [adopt] hashes
///   each one while copying it into `voice_models` and keeps the copy only
///   when size and SHA-256 match.
/// - Ids are app-assigned and persisted with the rows, so `list` keeps working
///   after a relaunch. A row whose transfer the system no longer knows (for
///   example the user force-quit the app) is reported as failed.
/// - Limits compared with Android: no system notification, and when iOS wakes
///   the app only to deliver background events, the app delegate does not call
///   the system completion handler, so the files are moved the next time the
///   app runs.
final class ModelDownloads: NSObject, URLSessionDownloadDelegate {
  private struct Row: Codable {
    var id: Int
    var path: String
    var status: String  // pending | running | paused | done | failed
    var received: Int64
    var total: Int64?
    var reason: Int
  }

  private let lock = NSLock()
  private var rows: [Int: Row] = [:]
  private var nextId = 1
  private var session: URLSession!
  private let work = DispatchQueue(label: "dev.openmosh.downloads.hash")

  private let fm = FileManager.default

  override init() {
    super.init()
    load()
    let config = URLSessionConfiguration.background(withIdentifier: "dev.openmosh.downloads")
    config.waitsForConnectivity = true
    config.httpCookieStorage = nil
    config.urlCredentialStorage = nil
    config.urlCache = nil
    session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
  }

  // MARK: Paths

  /// Same folder `path_provider` reports as the application support directory.
  private func supportDir() throws -> URL {
    var dir = try fm.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    #if os(macOS)
    if let id = Bundle.main.bundleIdentifier { dir.appendPathComponent(id, isDirectory: true) }
    #endif
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir
  }

  private func base() throws -> URL {
    var dir = try supportDir().appendingPathComponent("voice_downloads", isDirectory: true)
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? dir.setResourceValues(values)
    return dir.resolvingSymlinksInPath()
  }

  private struct PathError: Error { let message: String }

  /// [url] resolved, refusing anything outside [root].
  private func inside(_ root: URL, _ url: URL) throws -> URL {
    let r = root.resolvingSymlinksInPath().path
    let c = url.standardizedFileURL.resolvingSymlinksInPath()
    guard c.path.hasPrefix(r + "/") else { throw PathError(message: "path outside \(r)") }
    return c
  }

  private func stagingFile(_ path: String) throws -> URL {
    let root = try base()
    return try inside(root, root.appendingPathComponent(path))
  }

  // MARK: Persistence

  private func stateFile() -> URL? {
    try? base().deletingLastPathComponent().appendingPathComponent("voice_downloads.json")
  }

  private func load() {
    guard let f = stateFile(), let data = try? Data(contentsOf: f),
      let saved = try? JSONDecoder().decode([Row].self, from: data)
    else { return }
    for r in saved { rows[r.id] = r }
    nextId = (saved.map(\.id).max() ?? 0) + 1
  }

  /// Caller holds [lock].
  private func save() {
    guard let f = stateFile(), let data = try? JSONEncoder().encode(Array(rows.values)) else {
      return
    }
    try? data.write(to: f, options: .atomic)
  }

  // MARK: Channel

  func register(messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "dev.openmosh/downloads", binaryMessenger: messenger)
      .setMethodCallHandler { [weak self] call, result in
        self?.handle(call, result)
      }
  }

  private func handle(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    do {
      switch call.method {
      case "enqueue":
        guard let url = args["url"] as? String, let path = args["path"] as? String,
          let title = args["title"] as? String
        else { throw PathError(message: "bad arguments") }
        result(try enqueue(url: url, path: path, title: title))
      case "list":
        list(result)
      case "remove":
        let ids = (args["ids"] as? [NSNumber] ?? []).map { $0.intValue }
        remove(ids)
        result(nil)
      case "adopt":
        guard let path = args["path"] as? String, let dest = args["dest"] as? String,
          let sha = args["sha256"] as? String, let size = (args["size"] as? NSNumber)?.int64Value
        else { throw PathError(message: "bad arguments") }
        work.async {
          let ok = (try? self.adopt(path: path, dest: dest, sha: sha, size: size)) ?? false
          DispatchQueue.main.async { result(ok) }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let e as PathError {
      result(FlutterError(code: "download", message: e.message, details: nil))
    } catch {
      result(FlutterError(code: "download", message: error.localizedDescription, details: nil))
    }
  }

  // MARK: Operations

  private func enqueue(url: String, path: String, title: String) throws -> Int {
    guard let u = URL(string: url), u.scheme == "https" else {
      throw PathError(message: "https only")
    }
    let file = try stagingFile(path)
    try? fm.removeItem(at: file)  // A leftover would be mistaken for this download.
    try fm.createDirectory(
      at: file.deletingLastPathComponent(), withIntermediateDirectories: true)

    // The same path is never fetched twice at once.
    let replaced = locked { rows.values.filter { $0.path == path }.map(\.id) }
    remove(replaced)

    let id = locked { () -> Int in
      let id = nextId
      nextId += 1
      rows[id] = Row(
        id: id, path: path, status: "pending", received: 0, total: nil, reason: 0)
      save()
      return id
    }
    let task = session.downloadTask(with: u)
    task.taskDescription = String(id)
    task.earliestBeginDate = nil
    task.resume()
    return id
  }

  private func list(_ result: @escaping FlutterResult) {
    session.getAllTasks { tasks in
      let live = Dictionary(
        uniqueKeysWithValues: tasks.compactMap { t in
          t.taskDescription.flatMap(Int.init).map { ($0, t) }
        })
      let out: [[String: Any?]] = self.locked {
        var changed = false
        for (id, var r) in self.rows where r.status != "done" && r.status != "failed" {
          if let t = live[id] {
            r.received = t.countOfBytesReceived
            let exp = t.countOfBytesExpectedToReceive
            r.total = exp > 0 ? exp : nil
            r.status = t.state == .running ? (r.received > 0 ? "running" : "pending") : "paused"
          } else {
            // The system dropped the transfer without telling us.
            r.status = "failed"
            r.reason = NSURLErrorCancelled
            changed = true
          }
          self.rows[id] = r
        }
        if changed { self.save() }
        return self.rows.values.sorted { $0.id < $1.id }.map {
          [
            "id": $0.id, "path": $0.path, "status": $0.status,
            "received": $0.received, "total": $0.total, "reason": $0.reason,
          ]
        }
      }
      DispatchQueue.main.async { result(out) }
    }
  }

  private func remove(_ ids: [Int]) {
    guard !ids.isEmpty else { return }
    let gone: [Row] = locked {
      let gone = ids.compactMap { rows.removeValue(forKey: $0) }
      save()
      return gone
    }
    session.getAllTasks { tasks in
      let drop = Set(gone.map { String($0.id) })
      for t in tasks where t.taskDescription.map(drop.contains) ?? false { t.cancel() }
    }
    for r in gone { if let f = try? stagingFile(r.path) { try? fm.removeItem(at: f) } }
  }

  /// Streams the staging file into [dest] and the digest at once.
  private func adopt(path: String, dest: String, sha: String, size: Int64) throws -> Bool {
    let src = try stagingFile(path)
    // `path_provider`'s application support directory contains `voice_models`.
    let out = URL(fileURLWithPath: dest).standardizedFileURL
    let support = try supportDir().resolvingSymlinksInPath().path
    let resolvedOut = out.deletingLastPathComponent().resolvingSymlinksInPath()
      .appendingPathComponent(out.lastPathComponent)
    guard resolvedOut.path.hasPrefix(support + "/"),
      resolvedOut.path.contains("/voice_models/")
    else { throw PathError(message: "dest outside voice_models") }
    try fm.createDirectory(
      at: resolvedOut.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? fm.removeItem(at: resolvedOut)
    guard fm.createFile(atPath: resolvedOut.path, contents: nil) else { return false }

    do {
      let input = try FileHandle(forReadingFrom: src)
      let output = try FileHandle(forWritingTo: resolvedOut)
      defer {
        try? input.close()
        try? output.close()
      }
      var hasher = SHA256()
      var copied: Int64 = 0
      var withinSize = true
      while let chunk = try input.read(upToCount: 1 << 20), !chunk.isEmpty {
        copied += Int64(chunk.count)
        if copied > size {  // Larger than announced: stop, it cannot match.
          withinSize = false
          break
        }
        hasher.update(data: chunk)
        try output.write(contentsOf: chunk)
      }
      let hex = hasher.finalize().map { String(format: "%02x", $0) }.joined()
      if withinSize && copied == size && hex == sha.lowercased() { return true }
    } catch {
      // Falls through to the cleanup below.
    }
    try? fm.removeItem(at: resolvedOut)
    return false
  }

  private func locked<T>(_ body: () -> T) -> T {
    lock.lock()
    defer { lock.unlock() }
    return body()
  }

  // MARK: URLSessionDownloadDelegate

  private func rowId(_ task: URLSessionTask) -> Int? { task.taskDescription.flatMap(Int.init) }

  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64,
    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64
  ) {
    guard let id = rowId(downloadTask) else { return }
    locked {
      guard var r = rows[id], r.status != "done", r.status != "failed" else { return }
      r.received = totalBytesWritten
      r.total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : nil
      r.status = "running"
      rows[id] = r
    }
  }

  func urlSession(
    _ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo tmp: URL
  ) {
    guard let id = rowId(downloadTask), let row = locked({ rows[id] }) else { return }
    // The temporary file is deleted when this returns: move it right here.
    var status = "done"
    var reason = 0
    var size: Int64 = 0
    if let http = downloadTask.response as? HTTPURLResponse, http.statusCode != 200 {
      status = "failed"
      reason = http.statusCode
    } else {
      do {
        let file = try stagingFile(row.path)
        try? fm.removeItem(at: file)
        try fm.createDirectory(
          at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fm.moveItem(at: tmp, to: file)
        size = (try? fm.attributesOfItem(atPath: file.path)[.size] as? Int64) ?? 0
      } catch {
        status = "failed"
        reason = (error as NSError).code
      }
    }
    locked {
      guard var r = rows[id] else { return }
      r.status = status
      r.reason = reason
      if status == "done" {
        r.received = size
        r.total = size
      }
      rows[id] = r
      save()
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    guard let id = rowId(task), let e = error else { return }
    locked {
      guard var r = rows[id], r.status != "done" else { return }
      r.status = "failed"
      r.reason = (e as NSError).code
      rows[id] = r
      save()
    }
  }
}
