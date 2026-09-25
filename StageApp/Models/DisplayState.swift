import Foundation

struct DisplayState: Identifiable, Codable, Equatable, Sendable {
    var id: UInt32
    var name: String
    var frame: StageRect
    var visibleFrame: StageRect
    var scale: Double
    var isMain: Bool
}
