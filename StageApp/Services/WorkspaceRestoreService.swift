import AppKit
import Foundation

struct RestoreEvent: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var state: RestoreStepState
    var detail: String?

    enum RestoreStepState: String, Sendable {
        case running
        case succeeded
        case partial
        case failed
    }
}

enum WorkspaceRestoreService {
    static func restore(_ workspace: Workspace, hideUnrelated: Bool, minimizeUnmatched: Bool) -> AsyncStream<RestoreEvent> {
        AsyncStream { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                perform(workspace, hideUnrelated: hideUnrelated, minimizeUnmatched: minimizeUnmatched) { event in
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    private static func perform(
        _ workspace: Workspace,
        hideUnrelated: Bool,
        minimizeUnmatched: Bool,
        emit: (RestoreEvent) -> Void
    ) {
        let currentDisplays = DisplayManager.current()
        let mapper = FrameMapper(source: workspace.displays, target: currentDisplays)
        emit(RestoreEvent(
            id: "displays",
            title: "Displays",
            state: mapper.arrangementWarning == nil ? .succeeded : .partial,
            detail: mapper.arrangementWarning ?? "The saved display arrangement matches this desk."
        ))

        for application in workspace.applications {
            emit(RestoreEvent(id: application.bundleIdentifier, title: application.name, state: .running, detail: nil))
            let event = restore(application, mapper: mapper, minimizeUnmatched: minimizeUnmatched)
            emit(event)
        }

        if hideUnrelated {
            let keep = Set(workspace.applications.map(\.bundleIdentifier))
            let own = Bundle.main.bundleIdentifier
            var hidden = 0
            let others = NSWorkspace.shared.runningApplications.filter { app in
                guard app.activationPolicy == .regular, let id = app.bundleIdentifier else { return false }
                return id != own && !keep.contains(id) && !app.isHidden
            }
            DispatchQueue.main.sync {
                for app in others {
                    app.hide()
                    hidden += 1
                }
            }
            emit(RestoreEvent(
                id: "hide",
                title: "Other applications",
                state: .succeeded,
                detail: hidden == 0 ? "Nothing else needed to be hidden." : "Hid \(hidden) unrelated \(hidden == 1 ? "application" : "applications"). They were not quit."
            ))
        }

        let frontToBack = workspace.applications.sorted { $0.activationOrder > $1.activationOrder }
        for application in frontToBack {
            guard let running = NSRunningApplication.runningApplications(withBundleIdentifier: application.bundleIdentifier).first else { continue }
            DispatchQueue.main.sync {
                running.unhide()
                if #available(macOS 14.0, *) {
                    _ = running.activate(from: NSRunningApplication.current, options: [])
                } else {
                    running.activate(options: [])
                }
            }
        }

        emit(RestoreEvent(
            id: "finished",
            title: workspace.name,
            state: .succeeded,
            detail: "Restore finished. Stage did not quit anything that was already open."
        ))
    }

    private static func restore(_ application: ApplicationState, mapper: FrameMapper, minimizeUnmatched: Bool) -> RestoreEvent {
        let integration = IntegrationRegistry.integration(bundleIdentifier: application.bundleIdentifier, applicationName: application.name)
            ?? GenericApplicationIntegration()
        let created = integration.restore(application: application)
        if created.createdWindowCount == 0 {
            let launch = ApplicationLauncher.ensureRunning(bundleIdentifier: application.bundleIdentifier, bundlePath: application.bundlePath)
            if !launch.running {
                return RestoreEvent(
                    id: application.bundleIdentifier,
                    title: application.name,
                    state: .failed,
                    detail: launch.note ?? "The application did not launch."
                )
            }
        } else if !ApplicationLauncher.isRunning(bundleIdentifier: application.bundleIdentifier) {
            Thread.sleep(forTimeInterval: 0.4)
        }

        guard let pid = ApplicationLauncher.pid(bundleIdentifier: application.bundleIdentifier) else {
            return RestoreEvent(id: application.bundleIdentifier, title: application.name, state: .failed, detail: "The application did not stay running.")
        }
        if let running = NSRunningApplication.runningApplications(withBundleIdentifier: application.bundleIdentifier).first, running.isHidden {
            DispatchQueue.main.sync { running.unhide() }
        }
        if created.createdWindowCount > 0 {
            _ = WindowInspector.wait(pid: pid, minimumCount: created.createdWindowCount, timeout: 5)
            Thread.sleep(forTimeInterval: 0.25)
        }

        let applied = WindowInspector.apply(
            windows: application.windows,
            pid: pid,
            mapper: mapper,
            createdWindowCount: created.createdWindowCount,
            minimizeUnmatched: minimizeUnmatched,
            preserveTitles: Set(created.preserveTitles)
        )
        var notes = created.notes + applied.notes
        notes.removeAll { $0.isEmpty }
        let state: RestoreEvent.RestoreStepState
        if created.fidelity == .unsupported && applied.positioned == 0 {
            state = .failed
        } else if created.fidelity == .partial || applied.failed > 0 || (application.windows.count > 0 && applied.positioned == 0 && AccessibilityManager.isTrusted) {
            state = applied.positioned == 0 && application.windows.count > 0 ? .partial : .partial
        } else if created.fidelity == .full && applied.failed == 0 {
            state = .succeeded
        } else {
            state = .partial
        }
        return RestoreEvent(
            id: application.bundleIdentifier,
            title: application.name,
            state: state,
            detail: notes.isEmpty ? nil : notes.joined(separator: " ")
        )
    }
}
