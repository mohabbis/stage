import AppKit
import Foundation

enum DisplayManager {
    static func current() -> [DisplayState] {
        if Thread.isMainThread {
            return read()
        }
        return DispatchQueue.main.sync { read() }
    }

    private static func read() -> [DisplayState] {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return [] }
        let primary = screens.first { $0.frame.origin == .zero } ?? screens[0]
        let primaryHeight = primary.frame.height
        return screens.map { screen in
            let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
            return DisplayState(
                id: number,
                name: screen.localizedName,
                frame: StageRect(CoordinateSpace.quartz(fromCocoa: screen.frame, primaryHeight: primaryHeight)),
                visibleFrame: StageRect(CoordinateSpace.quartz(fromCocoa: screen.visibleFrame, primaryHeight: primaryHeight)),
                scale: Double(screen.backingScaleFactor),
                isMain: screen.frame.origin == .zero
            )
        }
    }
}
