import AppKit
import Foundation

enum WorkspaceCaptureService {
    static func capture(named name: String) -> Workspace {
        let displays = DisplayManager.current()
        let apps = ApplicationInspector.candidates()
        var states: [ApplicationState] = []
        let group = DispatchGroup()
        let lock = NSLock()
        var captures: [String: IntegrationCapture] = [:]

        let windowsByID: [String: [CapturedWindow]] = Dictionary(uniqueKeysWithValues: apps.compactMap { app in
            guard let bundleID = app.bundleIdentifier else { return nil }
            let captured = WindowInspector.capture(pid: app.processIdentifier, applicationName: app.localizedName ?? bundleID, displays: displays)
            return (bundleID, captured)
        })

        for app in apps {
            guard let bundleID = app.bundleIdentifier else { continue }
            let name = app.localizedName ?? bundleID
            let capturedWindows = windowsByID[bundleID] ?? []
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let context = IntegrationContext(
                    applicationName: name,
                    bundleIdentifier: bundleID,
                    bundlePath: app.bundleURL?.path,
                    windows: capturedWindows
                )
                let integration = IntegrationRegistry.integration(bundleIdentifier: bundleID, applicationName: name)
                    ?? GenericApplicationIntegration()
                let result = integration.capture(context: context)
                lock.lock()
                captures[bundleID] = result
                lock.unlock()
                group.leave()
            }
        }
        _ = group.wait(timeout: .now() + 4)

        var order = 0
        var skippedWindowless = 0
        for app in apps {
            guard let bundleID = app.bundleIdentifier else { continue }
            let capturedWindows = windowsByID[bundleID] ?? []
            if capturedWindows.isEmpty && !app.isHidden && !app.isActive {
                skippedWindowless += 1
                continue
            }
            let integration = captures[bundleID] ?? IntegrationCapture(resources: [], fidelity: .unsupported, notes: ["No windows could be read."])
            var fidelity = integration.fidelity
            if capturedWindows.isEmpty && integration.resources.isEmpty {
                fidelity = .unsupported
            }
            states.append(ApplicationState(
                id: UUID(),
                bundleIdentifier: bundleID,
                name: app.localizedName ?? bundleID,
                bundlePath: app.bundleURL?.path,
                activationOrder: app.isActive ? 0 : (order + 1),
                isHidden: app.isHidden,
                isFrontmost: app.isActive,
                windows: capturedWindows.map(\.window),
                resources: integration.resources,
                fidelity: fidelity,
                note: integration.notes.first
            ))
            if !app.isActive { order += 1 }
        }
        states.sort { lhs, rhs in
            if lhs.isFrontmost != rhs.isFrontmost { return lhs.isFrontmost && !rhs.isFrontmost }
            return lhs.activationOrder < rhs.activationOrder
        }
        for index in states.indices {
            states[index].activationOrder = index
            states[index].isFrontmost = index == 0
        }

        var limitations = ["Only the current Space was captured."]
        if !AccessibilityManager.isTrusted {
            limitations.append("Accessibility permission is off, so Stage could not read every window.")
        }
        if skippedWindowless > 0 {
            limitations.append("Applications that were running without windows were left out.")
        }
        let now = Date()
        return Workspace(
            id: UUID(),
            name: name,
            createdAt: now,
            updatedAt: now,
            lastRestoredAt: nil,
            displays: displays,
            applications: states,
            limitations: limitations
        )
    }
}
