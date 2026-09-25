import Foundation

struct FrameMapper: Equatable, Sendable {
    var source: [DisplayState]
    var target: [DisplayState]

    var arrangementWarning: String? {
        if source.isEmpty || target.isEmpty {
            return "No displays were available to map windows."
        }
        if source.count != target.count {
            return "This workspace was saved with \(source.count) \(source.count == 1 ? "display" : "displays"). \(target.count) \(target.count == 1 ? "is" : "are") connected now. Windows will be scaled into the displays that are here."
        }
        let pairs = zip(arranged(source), arranged(target))
        let same = pairs.allSatisfy { $0.frame.approximatelyEquals($1.frame, tolerance: 8) }
        if same { return nil }
        return "The display arrangement has changed since this workspace was saved. Windows will be scaled to fit."
    }

    func map(frame: StageRect, displayID: UInt32?) -> StageRect {
        let window = WindowState(
            id: UUID(),
            title: "",
            frame: frame,
            displayID: displayID,
            isMinimized: false,
            isFullscreen: false,
            isZoomed: false,
            isOnScreen: true,
            zOrder: 0
        )
        return map(window: window)
    }

    func map(window: WindowState) -> StageRect {
        guard let sourceDisplay = sourceDisplay(for: window), let destination = targetDisplay(for: window) else {
            return window.frame
        }
        if window.isFullscreen { return destination.frame }
        if window.isZoomed { return destination.visibleFrame }
        if sourceDisplay.frame.approximatelyEquals(destination.frame, tolerance: 8) {
            return window.frame
        }
        let mapped = relative(window.frame, from: sourceDisplay.frame, to: destination.frame)
        return clamp(mapped, to: destination.frame)
    }

    func targetDisplay(for window: WindowState) -> DisplayState? {
        guard let sourceDisplay = sourceDisplay(for: window) else {
            return target.first(where: \.isMain) ?? target.first
        }
        if let same = target.first(where: {
            $0.id == sourceDisplay.id && $0.frame.approximatelyEquals(sourceDisplay.frame, tolerance: 8)
        }) {
            return same
        }
        if let samePlace = target.first(where: {
            abs($0.frame.width - sourceDisplay.frame.width) < 8
                && abs($0.frame.height - sourceDisplay.frame.height) < 8
                && abs($0.frame.x - sourceDisplay.frame.x) < 8
                && abs($0.frame.y - sourceDisplay.frame.y) < 8
        }) {
            return samePlace
        }
        let sourceOrder = arranged(source)
        let targetOrder = arranged(target)
        if let index = sourceOrder.firstIndex(where: { $0.id == sourceDisplay.id }), index < targetOrder.count {
            return targetOrder[index]
        }
        return targetOrder.first
    }

    private func sourceDisplay(for window: WindowState) -> DisplayState? {
        if let displayID = window.displayID, let match = source.first(where: { $0.id == displayID }) {
            return match
        }
        return DisplayLocator.display(containing: window.frame.cgRect, displays: source)
    }

    private func relative(_ rect: StageRect, from source: StageRect, to target: StageRect) -> StageRect {
        let width = max(source.width, 1)
        let height = max(source.height, 1)
        return StageRect(
            x: target.x + ((rect.x - source.x) / width) * target.width,
            y: target.y + ((rect.y - source.y) / height) * target.height,
            width: (rect.width / width) * target.width,
            height: (rect.height / height) * target.height
        )
    }

    private func clamp(_ rect: StageRect, to display: StageRect) -> StageRect {
        var width = min(max(rect.width, min(80, display.width)), display.width)
        var height = min(max(rect.height, min(80, display.height)), display.height)
        var x = rect.x
        var y = rect.y
        if x < display.x { x = display.x }
        if y < display.y { y = display.y }
        if x + width > display.x + display.width { x = display.x + display.width - width }
        if y + height > display.y + display.height { y = display.y + display.height - height }
        return StageRect(x: x, y: y, width: width, height: height)
    }

    private func arranged(_ displays: [DisplayState]) -> [DisplayState] {
        displays.sorted {
            if abs($0.frame.x - $1.frame.x) > 2 { return $0.frame.x < $1.frame.x }
            return $0.frame.y < $1.frame.y
        }
    }
}
