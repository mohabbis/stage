import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct CapturedWindow: Sendable {
    var window: WindowState
    var documentLocator: String?
}

struct ApplyResult: Sendable {
    var positioned: Int
    var failed: Int
    var minimized: Int
    var notes: [String]
}

enum WindowInspector {
    static func capture(pid: pid_t, applicationName: String, displays: [DisplayState]) -> [CapturedWindow] {
        let axWindows = readAX(pid: pid)
        if !axWindows.isEmpty {
            return axWindows.enumerated().compactMap { index, element in
                makeCaptured(element: element, index: index, applicationName: applicationName, displays: displays)
            }
        }
        return cgWindows(pid: pid).enumerated().map { index, record in
            let frame = StageRect(record.bounds)
            let display = DisplayLocator.display(containing: record.bounds, displays: displays)
            let window = WindowState(
                id: UUID(),
                title: record.title.isEmpty ? applicationName : record.title,
                frame: frame,
                displayID: display?.id,
                isMinimized: !record.isOnScreen,
                isFullscreen: isFullscreen(frame.cgRect, displays: displays),
                isZoomed: isZoomed(frame.cgRect, displays: displays),
                isOnScreen: record.isOnScreen,
                zOrder: index
            )
            return CapturedWindow(window: window, documentLocator: nil)
        }
    }

    static func windowCount(pid: pid_t) -> Int {
        readAX(pid: pid).count
    }

    static func titles(pid: pid_t) -> [String] {
        readAX(pid: pid).map { copyString(kAXTitleAttribute, from: $0) ?? "" }
    }

    static func wait(pid: pid_t, minimumCount: Int, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if windowCount(pid: pid) >= minimumCount { return true }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return windowCount(pid: pid) >= minimumCount
    }

    static func apply(
        windows: [WindowState],
        pid: pid_t,
        mapper: FrameMapper,
        createdWindowCount: Int,
        minimizeUnmatched: Bool,
        preserveTitles: Set<String>
    ) -> ApplyResult {
        guard AccessibilityManager.isTrusted else {
            return ApplyResult(positioned: 0, failed: windows.count, minimized: 0, notes: [
                "Accessibility permission is required to move windows."
            ])
        }
        let live = readAX(pid: pid)
        let liveTitles = live.map { copyString(kAXTitleAttribute, from: $0) ?? "" }
        let matches = WindowMatcher.match(capturedTitles: windows.map(\.title), liveTitles: liveTitles)
        var usedLive = Set(matches.map(\.liveIndex))
        var usedCaptured = Set(matches.map(\.capturedIndex))
        var positioned = 0
        var failed = 0
        var placed: [(index: Int, zOrder: Int)] = []

        for match in matches {
            let window = windows[match.capturedIndex]
            if place(window, on: live[match.liveIndex], mapper: mapper) {
                positioned += 1
                placed.append((match.liveIndex, window.zOrder))
            } else {
                failed += 1
            }
        }

        if createdWindowCount > 0 {
            let unmatchedCaptured = windows.indices.filter { !usedCaptured.contains($0) }.sorted {
                windows[$0].zOrder < windows[$1].zOrder
            }
            let unmatchedLive = live.indices.filter { !usedLive.contains($0) }
            let count = min(createdWindowCount, unmatchedCaptured.count, unmatchedLive.count)
            for offset in 0..<count {
                let capturedIndex = unmatchedCaptured[offset]
                let liveIndex = unmatchedLive[offset]
                if place(windows[capturedIndex], on: live[liveIndex], mapper: mapper) {
                    positioned += 1
                    placed.append((liveIndex, windows[capturedIndex].zOrder))
                    usedLive.insert(liveIndex)
                    usedCaptured.insert(capturedIndex)
                } else {
                    failed += 1
                }
            }
        }

        for item in placed.sorted(by: { $0.zOrder > $1.zOrder }) {
            _ = AXUIElementPerformAction(live[item.index], kAXRaiseAction as CFString)
        }

        var minimized = 0
        if minimizeUnmatched && positioned > 0 {
            for index in live.indices where !usedLive.contains(index) {
                let title = liveTitles[index]
                if preserveTitles.contains(title) { continue }
                if setBool(true, attribute: kAXMinimizedAttribute, on: live[index]) {
                    minimized += 1
                }
            }
        }

        var notes: [String] = []
        if positioned > 0 { notes.append("Positioned \(positioned) \(positioned == 1 ? "window" : "windows").") }
        if failed > 0 { notes.append("Could not move \(failed) \(failed == 1 ? "window" : "windows").") }
        if minimized > 0 { notes.append("Minimized \(minimized) \(minimized == 1 ? "window" : "windows") that were not part of the workspace.") }
        if windows.isEmpty { notes.append("No windows to place.") }
        return ApplyResult(positioned: positioned, failed: failed, minimized: minimized, notes: notes)
    }

    private static func place(_ window: WindowState, on element: AXUIElement, mapper: FrameMapper) -> Bool {
        if copyBool(kAXMinimizedAttribute, from: element) == true {
            _ = setBool(false, attribute: kAXMinimizedAttribute, on: element)
            Thread.sleep(forTimeInterval: 0.15)
        }
        if copyBool("AXFullScreen", from: element) == true && !window.isFullscreen {
            _ = setBool(false, attribute: "AXFullScreen", on: element)
            Thread.sleep(forTimeInterval: 0.35)
        }

        let frame = mapper.map(window: window).cgRect
        let moved = setFrame(frame, on: element)
        if window.isFullscreen {
            Thread.sleep(forTimeInterval: 0.15)
            let entered = setBool(true, attribute: "AXFullScreen", on: element)
            return moved || entered
        }
        if window.isMinimized {
            _ = setBool(true, attribute: kAXMinimizedAttribute, on: element)
        }
        return moved
    }

    private static func makeCaptured(element: AXUIElement, index: Int, applicationName: String, displays: [DisplayState]) -> CapturedWindow? {
        AXUIElementSetMessagingTimeout(element, 0.25)
        let minimized = copyBool(kAXMinimizedAttribute, from: element) ?? false
        guard let origin = copyPoint(kAXPositionAttribute, from: element),
              let size = copySize(kAXSizeAttribute, from: element) else {
            return nil
        }
        if !minimized && (size.width < 48 || size.height < 32) { return nil }
        let rect = CGRect(origin: origin, size: size)
        let axTitle = copyString(kAXTitleAttribute, from: element)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fullscreen = copyBool("AXFullScreen", from: element) ?? isFullscreen(rect, displays: displays)
        let zoomed = !fullscreen && isZoomed(rect, displays: displays)
        let display = DisplayLocator.display(containing: rect, displays: displays)
        let window = WindowState(
            id: UUID(),
            title: axTitle.isEmpty ? applicationName : axTitle,
            frame: StageRect(rect),
            displayID: display?.id,
            isMinimized: minimized,
            isFullscreen: fullscreen,
            isZoomed: zoomed,
            isOnScreen: !minimized,
            zOrder: index
        )
        return CapturedWindow(window: window, documentLocator: normalizeDocument(copyString(kAXDocumentAttribute, from: element)))
    }

    private static func normalizeDocument(_ raw: String?) -> String? {
        guard let raw, !raw.isEmpty else { return nil }
        if let url = URL(string: raw), url.isFileURL {
            let path = url.path
            return ResourceValidator.isSafeAbsolutePath(path) ? path : nil
        }
        if ResourceValidator.isRestorableWebOrFileURL(raw) { return raw }
        if ResourceValidator.isSafeAbsolutePath(raw) { return raw }
        return nil
    }

    private static func isFullscreen(_ rect: CGRect, displays: [DisplayState]) -> Bool {
        displays.contains { rect.approximatelyEquals($0.frame.cgRect, tolerance: 8) }
    }

    private static func isZoomed(_ rect: CGRect, displays: [DisplayState]) -> Bool {
        displays.contains { rect.approximatelyEquals($0.visibleFrame.cgRect, tolerance: 12) }
    }

    private static func readAX(pid: pid_t) -> [AXUIElement] {
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, 0.4)
        guard let raw = copyAttribute(kAXWindowsAttribute, from: application) else { return [] }
        return raw as? [AXUIElement] ?? []
    }

    private static func cgWindows(pid: pid_t) -> [CGWindowRecord] {
        guard let info = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return info.compactMap { dict in
            guard let owner = dict[kCGWindowOwnerPID as String] as? Int32, owner == pid else { return nil }
            let layer = dict[kCGWindowLayer as String] as? Int ?? 0
            guard layer == 0 else { return nil }
            guard let boundsDict = dict[kCGWindowBounds as String] as? NSDictionary else { return nil }
            var bounds = CGRect.zero
            guard CGRectMakeWithDictionaryRepresentation(boundsDict, &bounds) else { return nil }
            let alpha = dict[kCGWindowAlpha as String] as? Double ?? 1
            guard alpha > 0.01 else { return nil }
            return CGWindowRecord(
                title: dict[kCGWindowName as String] as? String ?? "",
                bounds: bounds,
                isOnScreen: dict[kCGWindowIsOnscreen as String] as? Bool ?? true
            )
        }
    }

    private struct CGWindowRecord {
        var title: String
        var bounds: CGRect
        var isOnScreen: Bool
    }

    private static func copyAttribute(_ name: String, from element: AXUIElement) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func copyString(_ name: String, from element: AXUIElement) -> String? {
        copyAttribute(name, from: element) as? String
    }

    private static func copyBool(_ name: String, from element: AXUIElement) -> Bool? {
        guard let raw = copyAttribute(name, from: element), CFGetTypeID(raw) == CFBooleanGetTypeID() else { return nil }
        return CFBooleanGetValue((raw as! CFBoolean))
    }

    private static func copyPoint(_ name: String, from element: AXUIElement) -> CGPoint? {
        guard let raw = copyAttribute(name, from: element), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var point = CGPoint.zero
        guard AXValueGetValue(raw as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    private static func copySize(_ name: String, from element: AXUIElement) -> CGSize? {
        guard let raw = copyAttribute(name, from: element), CFGetTypeID(raw) == AXValueGetTypeID() else { return nil }
        var size = CGSize.zero
        guard AXValueGetValue(raw as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    @discardableResult
    private static func setFrame(_ rect: CGRect, on element: AXUIElement) -> Bool {
        var size = rect.size
        var origin = rect.origin
        guard let sizeValue = AXValueCreate(.cgSize, &size), let originValue = AXValueCreate(.cgPoint, &origin) else {
            return false
        }
        let sizeOK = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue) == .success
        let originOK = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, originValue) == .success
        _ = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
        _ = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, originValue)
        return sizeOK && originOK
    }

    @discardableResult
    private static func setBool(_ value: Bool, attribute: String, on element: AXUIElement) -> Bool {
        let flag: CFBoolean = value ? kCFBooleanTrue : kCFBooleanFalse
        return AXUIElementSetAttributeValue(element, attribute as CFString, flag) == .success
    }
}

private extension CGRect {
    func approximatelyEquals(_ other: CGRect, tolerance: CGFloat) -> Bool {
        abs(minX - other.minX) <= tolerance
            && abs(minY - other.minY) <= tolerance
            && abs(width - other.width) <= tolerance
            && abs(height - other.height) <= tolerance
    }
}
