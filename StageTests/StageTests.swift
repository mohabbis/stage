import XCTest
@testable import Stage

final class GeometryTests: XCTestCase {
    func testQuartzRoundTrip() {
        let cocoa = CGRect(x: 100, y: 200, width: 400, height: 300)
        let quartz = CoordinateSpace.quartz(fromCocoa: cocoa, primaryHeight: 1000)
        let back = CoordinateSpace.cocoa(fromQuartz: quartz, primaryHeight: 1000)
        XCTAssertEqual(back.origin.x, cocoa.origin.x, accuracy: 0.01)
        XCTAssertEqual(back.origin.y, cocoa.origin.y, accuracy: 0.01)
        XCTAssertEqual(back.height, cocoa.height, accuracy: 0.01)
    }

    func testEconLayoutPhrases() {
        let display = DisplayState(id: 1, name: "Display", frame: StageRect(x: 0, y: 0, width: 1000, height: 800), visibleFrame: StageRect(x: 0, y: 0, width: 1000, height: 775), scale: 2, isMain: true)
        let safari = window(x: 0, y: 0, width: 600, height: 800)
        let preview = window(x: 600, y: 0, width: 400, height: 800)
        XCTAssertEqual(LayoutPhrase.describe(window: safari, display: display), "Left 60%")
        XCTAssertEqual(LayoutPhrase.describe(window: preview, display: display), "Right 40%")
    }

    private func window(x: Double, y: Double, width: Double, height: Double) -> WindowState {
        WindowState(id: UUID(), title: "Window", frame: StageRect(x: x, y: y, width: width, height: height), displayID: 1, isMinimized: false, isFullscreen: false, isZoomed: false, isOnScreen: true, zOrder: 0)
    }
}

final class FrameMapperTests: XCTestCase {
    func testIdenticalTopologyPreservesFrame() {
        let display = DisplayState(id: 1, name: "Built-in", frame: StageRect(x: 0, y: 0, width: 1440, height: 900), visibleFrame: StageRect(x: 0, y: 25, width: 1440, height: 875), scale: 2, isMain: true)
        let mapper = FrameMapper(source: [display], target: [display])
        let frame = StageRect(x: 40, y: 80, width: 800, height: 600)
        XCTAssertEqual(mapper.map(frame: frame, displayID: 1), frame)
        XCTAssertNil(mapper.arrangementWarning)
    }

    func testRelativeLeftSixtyOnADifferentDisplay() {
        let source = DisplayState(id: 1, name: "A", frame: StageRect(x: 0, y: 0, width: 1000, height: 800), visibleFrame: StageRect(x: 0, y: 0, width: 1000, height: 800), scale: 2, isMain: true)
        let target = DisplayState(id: 2, name: "B", frame: StageRect(x: 0, y: 0, width: 2000, height: 1000), visibleFrame: StageRect(x: 0, y: 0, width: 2000, height: 1000), scale: 2, isMain: true)
        let mapper = FrameMapper(source: [source], target: [target])
        let mapped = mapper.map(frame: StageRect(x: 0, y: 0, width: 600, height: 800), displayID: 1)
        XCTAssertEqual(mapped.x, 0, accuracy: 0.5)
        XCTAssertEqual(mapped.width, 1200, accuracy: 0.5)
    }
}

final class WindowMatcherTests: XCTestCase {
    func testUniqueTitlesMatch() {
        let matches = WindowMatcher.match(capturedTitles: ["Canvas", "Notes"], liveTitles: ["Notes", "Canvas"])
        XCTAssertEqual(matches.count, 2)
        XCTAssertEqual(matches.first { $0.capturedIndex == 0 }?.liveIndex, 1)
    }

    func testEmptyTitlesDoNotExactMatch() {
        let matches = WindowMatcher.match(capturedTitles: ["", ""], liveTitles: ["", ""])
        XCTAssertTrue(matches.isEmpty)
    }
}

final class ResourceValidatorTests: XCTestCase {
    func testRejectsUnsafeLocators() {
        XCTAssertFalse(ResourceValidator.isRestorableWebOrFileURL("javascript:alert(1)"))
        XCTAssertFalse(ResourceValidator.isSafeAbsolutePath("relative/path"))
        XCTAssertTrue(ResourceValidator.isRestorableWebOrFileURL("https://fred.stlouisfed.org"))
        XCTAssertEqual(AppleScript.literal("a\"b"), "\"a\\\"b\"")
    }

    func testForegroundTTYProcess() {
        let pid = TTYProcess.foregroundPID(psOutput: "  10 Ss\n  11 S+\n")
        XCTAssertEqual(pid, 11)
    }
}

final class WorkspaceCodingTests: XCTestCase {
    func testRoundTrip() throws {
        let workspace = Workspace(
            id: UUID(),
            name: "ECON 402",
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastRestoredAt: nil,
            displays: [DisplayState(id: 1, name: "Built-in", frame: StageRect(x: 0, y: 0, width: 1000, height: 800), visibleFrame: StageRect(x: 0, y: 25, width: 1000, height: 775), scale: 2, isMain: true)],
            applications: [],
            limitations: ["Only the current Space was captured."]
        )
        let data = try StageJSON.encoder.encode(workspace)
        let decoded = try StageJSON.decoder.decode(Workspace.self, from: data)
        XCTAssertEqual(decoded.name, "ECON 402")
        XCTAssertEqual(decoded.displays.first?.frame.width, 1000)
    }
}
