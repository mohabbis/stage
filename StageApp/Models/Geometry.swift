import CoreGraphics
import Foundation

struct StageRect: Codable, Equatable, Sendable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    init(_ rect: CGRect) {
        x = Double(rect.origin.x)
        y = Double(rect.origin.y)
        width = Double(rect.size.width)
        height = Double(rect.size.height)
    }

    var cgRect: CGRect {
        CGRect(x: x, y: y, width: width, height: height)
    }

    var center: CGPoint {
        CGPoint(x: x + width / 2, y: y + height / 2)
    }

    func approximatelyEquals(_ other: StageRect, tolerance: Double = 2) -> Bool {
        abs(x - other.x) <= tolerance
            && abs(y - other.y) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}

enum CoordinateSpace {
    /// Quartz and Accessibility share a top-left origin on the primary display, y down.
    /// AppKit's NSScreen uses a bottom-left origin on that same display, y up.
    static func quartz(fromCocoa rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    static func cocoa(fromQuartz rect: CGRect, primaryHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: primaryHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }
}

enum DisplayLocator {
    static func union(of displays: [DisplayState]) -> StageRect {
        guard let first = displays.first else {
            return StageRect(x: 0, y: 0, width: 1, height: 1)
        }
        var minX = first.frame.x
        var minY = first.frame.y
        var maxX = first.frame.x + first.frame.width
        var maxY = first.frame.y + first.frame.height
        for display in displays.dropFirst() {
            minX = min(minX, display.frame.x)
            minY = min(minY, display.frame.y)
            maxX = max(maxX, display.frame.x + display.frame.width)
            maxY = max(maxY, display.frame.y + display.frame.height)
        }
        return StageRect(x: minX, y: minY, width: max(maxX - minX, 1), height: max(maxY - minY, 1))
    }

    static func display(containing frame: CGRect, displays: [DisplayState]) -> DisplayState? {
        var best: (DisplayState, Double)?
        for display in displays {
            let area = intersectionArea(frame, display.frame.cgRect)
            if area > 0, best == nil || area > best!.1 {
                best = (display, area)
            }
        }
        if let best { return best.0 }
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return displays.min { lhs, rhs in
            distance(center, lhs.frame.center) < distance(center, rhs.frame.center)
        }
    }

    static func intersectionArea(_ a: CGRect, _ b: CGRect) -> Double {
        guard a.intersects(b) else { return 0 }
        let intersection = a.intersection(b)
        guard !intersection.isNull, !intersection.isInfinite else { return 0 }
        return Double(intersection.width * intersection.height)
    }

    private static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return (dx * dx + dy * dy).squareRoot()
    }
}

enum LayoutPhrase {
    static func describe(window: WindowState, display: DisplayState) -> String {
        if window.isMinimized { return "Minimized" }
        if window.isFullscreen { return "Fullscreen" }
        if window.isZoomed { return "Zoomed" }

        let width = max(display.frame.width, 1)
        let height = max(display.frame.height, 1)
        let relX = (window.frame.x - display.frame.x) / width
        let relY = (window.frame.y - display.frame.y) / height
        let relW = window.frame.width / width
        let relH = window.frame.height / height
        if relW > 0.92 && relH > 0.92 { return "Full display" }

        let percent = Int((min(max(relW, 0), 1) * 100).rounded())
        let center = relX + relW / 2
        let horizontal: String
        if relW > 0.92 {
            horizontal = "Full width"
        } else if center < 0.45 {
            horizontal = "Left \(percent)%"
        } else if center > 0.55 {
            horizontal = "Right \(percent)%"
        } else {
            horizontal = "Center \(percent)%"
        }

        if relH > 0.88 { return horizontal }
        let verticalCenter = relY + relH / 2
        if verticalCenter < 0.42 { return horizontal + " · upper" }
        if verticalCenter > 0.58 { return horizontal + " · lower" }
        return horizontal
    }
}
