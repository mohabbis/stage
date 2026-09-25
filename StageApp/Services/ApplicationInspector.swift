import AppKit
import Foundation

enum ApplicationInspector {
    private static let ignored: Set<String> = [
        "com.apple.dock",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.systemuiserver",
        "com.apple.WindowManager",
        "com.apple.Spotlight",
        "com.apple.screencaptureui"
    ]

    static func candidates() -> [NSRunningApplication] {
        let own = Bundle.main.bundleIdentifier
        return NSWorkspace.shared.runningApplications.filter { app in
            guard app.activationPolicy == .regular, !app.isTerminated else { return false }
            guard let bundleID = app.bundleIdentifier, bundleID != own, !ignored.contains(bundleID) else { return false }
            return true
        }
    }
}
