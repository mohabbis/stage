import Foundation

enum ResourceKind: String, Codable, Equatable, Sendable {
    case browserTab
    case finderFolder
    case terminalDirectory
    case document
    case editorWorkspace

    var label: String {
        switch self {
        case .browserTab: "Tab"
        case .finderFolder: "Folder"
        case .terminalDirectory: "Directory"
        case .document: "Document"
        case .editorWorkspace: "Project"
        }
    }
}

struct RestorableResource: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var kind: ResourceKind
    var title: String
    var locator: String
    var windowID: UUID?
    var index: Int
    var fidelity: CaptureFidelity
    var note: String?
}
