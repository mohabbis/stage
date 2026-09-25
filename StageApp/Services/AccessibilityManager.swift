import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

enum AccessibilityManager {
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    static var hasScreenRecording: Bool {
        CGPreflightScreenCaptureAccess()
    }

    @discardableResult
    static func requestAccessibility() -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    @discardableResult
    static func requestScreenRecording() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    static func openAccessibilitySettings() {
        open(urlString: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")
    }

    static func openScreenRecordingSettings() {
        open(urlString: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture")
    }

    private static func open(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}
