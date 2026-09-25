import Foundation

struct WindowState: Identifiable, Codable, Equatable, Sendable {
    var id: UUID
    var title: String
    var frame: StageRect
    var displayID: UInt32?
    var isMinimized: Bool
    var isFullscreen: Bool
    var isZoomed: Bool
    var isOnScreen: Bool
    var zOrder: Int
}
