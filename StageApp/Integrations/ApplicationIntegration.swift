import Foundation

struct IntegrationContext: Sendable {
    var applicationName: String
    var bundleIdentifier: String
    var bundlePath: String?
    var windows: [CapturedWindow]
}

struct IntegrationCapture: Sendable {
    var resources: [RestorableResource]
    var fidelity: CaptureFidelity
    var notes: [String]
}

struct IntegrationRestore: Sendable {
    var fidelity: CaptureFidelity
    var notes: [String]
    var createdWindowCount: Int
    var preserveTitles: [String]
}

protocol ApplicationIntegration: Sendable {
    func capture(context: IntegrationContext) -> IntegrationCapture
    func restore(application: ApplicationState) -> IntegrationRestore
}

enum IntegrationRegistry {
    static func integration(bundleIdentifier: String, applicationName: String) -> (any ApplicationIntegration)? {
        if BrowserIntegration.supports(bundleIdentifier: bundleIdentifier, applicationName: applicationName) {
            return BrowserIntegration(applicationName: applicationName, bundleIdentifier: bundleIdentifier)
        }
        if bundleIdentifier == "com.apple.finder" {
            return FinderIntegration()
        }
        if TerminalIntegration.supports(bundleIdentifier: bundleIdentifier) {
            return TerminalIntegration(applicationName: applicationName, bundleIdentifier: bundleIdentifier)
        }
        if VSCodeIntegration.supports(bundleIdentifier: bundleIdentifier, applicationName: applicationName) {
            return VSCodeIntegration(applicationName: applicationName, bundleIdentifier: bundleIdentifier)
        }
        return nil
    }
}

enum ScriptMessages {
    static func friendly(_ error: String, subject: String) -> String {
        let lower = error.lowercased()
        if lower.contains("not authorized") || lower.contains("-1743") || lower.contains("-1002") {
            return "Automation permission was denied. \(subject)"
        }
        if lower.contains("timed out") {
            return "Reading \(subject.lowercased()) timed out."
        }
        return subject
    }
}
