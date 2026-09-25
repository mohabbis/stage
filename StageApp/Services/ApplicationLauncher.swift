import AppKit
import Foundation

struct LaunchResult: Sendable {
    var running: Bool
    var note: String?
}

enum ApplicationLauncher {
    static func pid(bundleIdentifier: String) -> pid_t? {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier)
            .first { !$0.isTerminated }?
            .processIdentifier
    }

    static func isRunning(bundleIdentifier: String) -> Bool {
        pid(bundleIdentifier: bundleIdentifier) != nil
    }

    @discardableResult
    static func ensureRunning(bundleIdentifier: String, bundlePath: String?) -> LaunchResult {
        if isRunning(bundleIdentifier: bundleIdentifier) {
            return LaunchResult(running: true, note: nil)
        }
        return open(bundleIdentifier: bundleIdentifier, bundlePath: bundlePath, arguments: [])
    }

    @discardableResult
    static func open(bundleIdentifier: String, bundlePath: String?, arguments: [String]) -> LaunchResult {
        let url: URL?
        if let bundlePath, FileManager.default.fileExists(atPath: bundlePath) {
            url = URL(fileURLWithPath: bundlePath)
        } else {
            url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        }
        guard let url else {
            return LaunchResult(running: false, note: "The application is not installed.")
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        configuration.arguments = arguments
        let box = WaitBox()
        NSWorkspace.shared.openApplication(at: url, configuration: configuration) { app, error in
            box.finish(ok: app != nil && error == nil, note: error?.localizedDescription)
        }
        _ = box.wait(timeout: 8)
        if box.ok || isRunning(bundleIdentifier: bundleIdentifier) {
            return LaunchResult(running: true, note: nil)
        }
        return LaunchResult(running: false, note: box.note ?? "The application did not launch.")
    }

    static func openFile(_ path: String, bundleIdentifier: String, bundlePath: String?) -> LaunchResult {
        guard ResourceValidator.isSafeAbsolutePath(path), FileManager.default.fileExists(atPath: path) else {
            return LaunchResult(running: false, note: "The file is no longer there.")
        }
        let fileURL = URL(fileURLWithPath: path)
        let appURL: URL?
        if let bundlePath, FileManager.default.fileExists(atPath: bundlePath) {
            appURL = URL(fileURLWithPath: bundlePath)
        } else {
            appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        let box = WaitBox()
        if let appURL {
            NSWorkspace.shared.open([fileURL], withApplicationAt: appURL, configuration: configuration) { _, error in
                box.finish(ok: error == nil, note: error?.localizedDescription)
            }
        } else {
            NSWorkspace.shared.open(fileURL, configuration: configuration) { _, error in
                box.finish(ok: error == nil, note: error?.localizedDescription)
            }
        }
        _ = box.wait(timeout: 6)
        return LaunchResult(running: box.ok, note: box.ok ? nil : (box.note ?? "The document could not be opened."))
    }
}

final class WaitBox: @unchecked Sendable {
    private let lock = NSLock()
    private var done = false
    private(set) var ok = false
    private(set) var note: String?

    func finish(ok: Bool, note: String?) {
        lock.lock()
        self.ok = ok
        self.note = note
        done = true
        lock.unlock()
    }

    func wait(timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            lock.lock()
            let finished = done
            lock.unlock()
            if finished { return true }
            Thread.sleep(forTimeInterval: 0.05)
        }
        return false
    }
}
