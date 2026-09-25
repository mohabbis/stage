import Foundation

struct ApplicationState: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var bundleIdentifier: String
    var name: String
    var bundlePath: String?
    var activationOrder: Int
    var isHidden: Bool
    var isFrontmost: Bool
    var windows: [WindowState]
    var resources: [RestorableResource]
    var fidelity: CaptureFidelity
    var note: String?
}
