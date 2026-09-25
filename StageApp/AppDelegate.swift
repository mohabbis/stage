import AppKit
import SwiftUI

extension Notification.Name {
    static let stageCaptureRequested = Notification.Name("stage.capture")
}

@MainActor
final class WindowOpener {
    static let shared = WindowOpener()
    var openMain: (() -> Void)?
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            Task { @MainActor in
                WindowOpener.shared.openMain?()
                NSApp.activate()
            }
        }
        return true
    }
}

struct StageCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Save Workspace…") {
                NotificationCenter.default.post(name: .stageCaptureRequested, object: nil)
            }
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}
