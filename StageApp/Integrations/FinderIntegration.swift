import Foundation

struct FinderIntegration: ApplicationIntegration {
    func capture(context: IntegrationContext) -> IntegrationCapture {
        let result = AppleScriptRunner().run(
            """
            tell application "Finder"
                set output to ""
                repeat with w in windows
                    try
                        set output to output & POSIX path of (target of w as alias) & linefeed
                    on error
                        set output to output & linefeed
                    end try
                end repeat
                return output
            end tell
            """,
            timeout: 2.5
        )
        guard result.succeeded else {
            return IntegrationCapture(
                resources: [],
                fidelity: context.windows.isEmpty ? .unsupported : .partial,
                notes: [ScriptMessages.friendly(result.error ?? "Folders were not captured.", subject: "Finder folders were not captured.")]
            )
        }
        let paths = result.output.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        var resources: [RestorableResource] = []
        for (index, path) in paths.enumerated() where ResourceValidator.isSafeAbsolutePath(path) {
            let windowID = index < context.windows.count ? context.windows[index].window.id : nil
            resources.append(RestorableResource(
                id: UUID(),
                kind: .finderFolder,
                title: (path as NSString).lastPathComponent,
                locator: path,
                windowID: windowID,
                index: index,
                fidelity: .full,
                note: nil
            ))
        }
        let fidelity: CaptureFidelity = context.windows.isEmpty && resources.isEmpty ? .unsupported : .full
        let note = resources.isEmpty ? "Window layout." : "Window layout and open folders."
        return IntegrationCapture(resources: resources, fidelity: fidelity, notes: [note])
    }

    func restore(application: ApplicationState) -> IntegrationRestore {
        let folders = application.resources
            .filter { $0.kind == .finderFolder && ResourceValidator.isSafeAbsolutePath($0.locator) }
            .sorted { $0.index < $1.index }
        guard !folders.isEmpty else {
            return IntegrationRestore(fidelity: .full, notes: [], createdWindowCount: 0, preserveTitles: ["Desktop"])
        }
        var lines = ["tell application \"Finder\"", "activate"]
        for folder in folders {
            lines.append("try")
            lines.append("make new Finder window to (POSIX file \(AppleScript.literal(folder.locator)) as alias)")
            lines.append("end try")
        }
        lines.append("end tell")
        let result = AppleScriptRunner().run(lines.joined(separator: "\n"), timeout: 6)
        if result.succeeded {
            return IntegrationRestore(
                fidelity: .full,
                notes: ["Opened the saved Finder folders."],
                createdWindowCount: folders.count,
                preserveTitles: ["Desktop"]
            )
        }
        return IntegrationRestore(
            fidelity: .partial,
            notes: [ScriptMessages.friendly(result.error ?? "Finder folders were not opened.", subject: "Finder folders were not opened.")],
            createdWindowCount: 0,
            preserveTitles: ["Desktop"]
        )
    }
}
