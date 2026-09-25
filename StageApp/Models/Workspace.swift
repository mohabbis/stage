import Foundation

struct Workspace: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    var lastRestoredAt: Date?
    var displays: [DisplayState]
    var applications: [ApplicationState]
    var limitations: [String]

    var windowCount: Int {
        applications.reduce(0) { $0 + $1.windows.count }
    }

    var fidelity: CaptureFidelity {
        CaptureFidelity.aggregate(applications.map(\.fidelity))
    }

    func windows(on display: DisplayState) -> [(ApplicationState, WindowState)] {
        applications.flatMap { app in
            app.windows.compactMap { window in
                let owns: Bool
                if let displayID = window.displayID {
                    owns = displayID == display.id
                } else {
                    owns = DisplayLocator.display(containing: window.frame.cgRect, displays: [display])?.id == display.id
                }
                return owns ? (app, window) : nil
            }
        }
    }

    func matches(query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        let needle = trimmed.lowercased()
        if name.lowercased().contains(needle) { return true }
        return applications.contains {
            $0.name.lowercased().contains(needle) || $0.bundleIdentifier.lowercased().contains(needle)
        }
    }
}
