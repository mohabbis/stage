import Darwin
import Foundation

enum TTYProcess {
    static func foregroundPID(psOutput: String) -> pid_t? {
        var fallback: pid_t?
        for line in psOutput.split(separator: "\n") {
            let parts = line.split(whereSeparator: { $0 == " " || $0 == "\t" }).map(String.init)
            guard let first = parts.first, let pid = pid_t(first) else { continue }
            fallback = pid
            if parts.count > 1, parts[1].contains("+") {
                return pid
            }
        }
        return fallback
    }

    static func workingDirectory(pid: pid_t) -> String? {
        var info = proc_vnodepathinfo()
        let size = proc_pidinfo(pid, PROC_PIDVNODEPATHINFO, 0, &info, Int32(MemoryLayout<proc_vnodepathinfo>.size))
        guard size > 0 else { return nil }
        let raw = withUnsafePointer(to: info.pvi_cdir.vip_path) { pointer -> String in
            pointer.withMemoryRebound(to: CChar.self, capacity: Int(MAXPATHLEN)) {
                String(cString: $0)
            }
        }
        guard ResourceValidator.isSafeAbsolutePath(raw) else { return nil }
        return raw
    }
}

struct TerminalIntegration: ApplicationIntegration {
    var applicationName: String
    var bundleIdentifier: String

    static func supports(bundleIdentifier: String) -> Bool {
        bundleIdentifier == "com.apple.Terminal" || bundleIdentifier == "com.googlecode.iterm2"
    }

    private var isITerm: Bool { bundleIdentifier == "com.googlecode.iterm2" }

    func capture(context: IntegrationContext) -> IntegrationCapture {
        let script = isITerm ? iTermTTYScript : terminalTTYScript
        let result = AppleScriptRunner().run(script, timeout: 2.5)
        guard result.succeeded else {
            return IntegrationCapture(
                resources: [],
                fidelity: context.windows.isEmpty ? .unsupported : .partial,
                notes: [ScriptMessages.friendly(result.error ?? "Working directories were not captured.", subject: "Working directories were not captured.")]
            )
        }
        let ttys = result.output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var resources: [RestorableResource] = []
        for (index, tty) in ttys.enumerated() {
            guard let path = directory(forTTY: tty) else { continue }
            let windowID = index < context.windows.count ? context.windows[index].window.id : nil
            resources.append(RestorableResource(
                id: UUID(),
                kind: .terminalDirectory,
                title: (path as NSString).lastPathComponent,
                locator: path,
                windowID: windowID,
                index: index,
                fidelity: .full,
                note: nil
            ))
        }
        let fidelity: CaptureFidelity = (context.windows.isEmpty && resources.isEmpty) ? .unsupported : (resources.isEmpty ? .partial : .full)
        let note = resources.isEmpty ? "Window layout. Working directories were not available." : "Window layout and working directories."
        return IntegrationCapture(resources: resources, fidelity: fidelity, notes: [note])
    }

    func restore(application: ApplicationState) -> IntegrationRestore {
        let directories = application.resources
            .filter { $0.kind == .terminalDirectory && ResourceValidator.isSafeAbsolutePath($0.locator) }
            .sorted { $0.index < $1.index }
        guard !directories.isEmpty else {
            return IntegrationRestore(fidelity: .partial, notes: ["No working directory was saved."], createdWindowCount: 0, preserveTitles: [])
        }
        let script = isITerm ? iTermRestore(directories) : terminalRestore(directories)
        let result = AppleScriptRunner().run(script, timeout: 8)
        if result.succeeded {
            return IntegrationRestore(
                fidelity: .full,
                notes: ["Opened the saved working directories."],
                createdWindowCount: directories.count,
                preserveTitles: []
            )
        }
        return IntegrationRestore(
            fidelity: .partial,
            notes: [ScriptMessages.friendly(result.error ?? "Working directories were not opened.", subject: "Working directories were not opened.")],
            createdWindowCount: 0,
            preserveTitles: []
        )
    }

    private func directory(forTTY tty: String) -> String? {
        let trimmed = tty.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let name = (trimmed as NSString).lastPathComponent
        guard let pid = TTYProcess.foregroundPID(psOutput: shell("/bin/ps", ["-t", name, "-o", "pid=,stat="])) else { return nil }
        return TTYProcess.workingDirectory(pid: pid)
    }

    private func shell(_ launchPath: String, _ arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ""
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }

    private var terminalTTYScript: String {
        """
        tell application "Terminal"
            set output to ""
            repeat with w in windows
                try
                    set output to output & (tty of selected tab of w) & linefeed
                on error
                    set output to output & linefeed
                end try
            end repeat
            return output
        end tell
        """
    }

    private var iTermTTYScript: String {
        """
        tell application \(AppleScript.literal(applicationName))
            set output to ""
            repeat with w in windows
                try
                    tell w
                        set output to output & (tty of current session) & linefeed
                    end tell
                on error
                    set output to output & linefeed
                end try
            end repeat
            return output
        end tell
        """
    }

    private func terminalRestore(_ directories: [RestorableResource]) -> String {
        var lines = ["tell application \"Terminal\"", "activate"]
        for directory in directories {
            let title = (directory.locator as NSString).lastPathComponent
            lines.append("set newTab to do script \"cd \" & quoted form of \(AppleScript.literal(directory.locator))")
            lines.append("set custom title of newTab to \(AppleScript.literal(title))")
        }
        lines.append("end tell")
        return lines.joined(separator: "\n")
    }

    private func iTermRestore(_ directories: [RestorableResource]) -> String {
        var lines = ["tell application \(AppleScript.literal(applicationName))", "activate"]
        for directory in directories {
            lines.append("set newWindow to (create window with default profile)")
            lines.append("tell current session of newWindow")
            lines.append("write text \"cd \" & quoted form of \(AppleScript.literal(directory.locator))")
            lines.append("end tell")
        }
        lines.append("end tell")
        return lines.joined(separator: "\n")
    }
}
