import Foundation

struct BrowserIntegration: ApplicationIntegration {
    var applicationName: String
    var bundleIdentifier: String

    private var dialect: Dialect {
        Self.dialect(bundleIdentifier: bundleIdentifier, applicationName: applicationName)
    }

    static func supports(bundleIdentifier: String, applicationName: String) -> Bool {
        dialect(bundleIdentifier: bundleIdentifier, applicationName: applicationName) != .unknown
    }

    func capture(context: IntegrationContext) -> IntegrationCapture {
        switch dialect {
        case .firefox:
            return IntegrationCapture(
                resources: [],
                fidelity: context.windows.isEmpty ? .unsupported : .partial,
                notes: ["Firefox does not expose its tabs. Window layout was captured."]
            )
        case .unknown:
            return IntegrationCapture(resources: [], fidelity: .partial, notes: ["Tabs were not captured."])
        case .safari, .chromium:
            let script = dialect == .safari ? safariCaptureScript : chromiumCaptureScript
            let result = AppleScriptRunner().run(script, timeout: 3)
            guard result.succeeded else {
                return IntegrationCapture(
                    resources: [],
                    fidelity: context.windows.isEmpty ? .unsupported : .partial,
                    notes: [ScriptMessages.friendly(result.error ?? "Tabs could not be read.", subject: "Tabs were not captured.")]
                )
            }
            let groups = Self.parse(result.output)
            var resources: [RestorableResource] = []
            for (windowIndex, tabs) in groups.enumerated() {
                let windowID = windowIndex < context.windows.count ? context.windows[windowIndex].window.id : nil
                for (tabIndex, tab) in tabs.enumerated() where ResourceValidator.isRestorableWebOrFileURL(tab.locator) {
                    resources.append(RestorableResource(
                        id: UUID(),
                        kind: .browserTab,
                        title: tab.title.isEmpty ? tab.locator : tab.title,
                        locator: tab.locator,
                        windowID: windowID,
                        index: tabIndex,
                        fidelity: .full,
                        note: nil
                    ))
                }
            }
            if resources.isEmpty && context.windows.isEmpty {
                return IntegrationCapture(resources: [], fidelity: .unsupported, notes: ["No windows or tabs were open."])
            }
            let note = resources.isEmpty ? "Window layout. No tabs were open." : "Window layout and tabs."
            return IntegrationCapture(resources: resources, fidelity: .full, notes: [note])
        }
    }

    func restore(application: ApplicationState) -> IntegrationRestore {
        let groups = Self.tabGroups(in: application)
        guard dialect == .safari || dialect == .chromium, !groups.isEmpty else {
            if dialect == .firefox {
                return IntegrationRestore(fidelity: .partial, notes: ["Firefox tabs cannot be restored."], createdWindowCount: 0, preserveTitles: [])
            }
            return IntegrationRestore(fidelity: .full, notes: [], createdWindowCount: 0, preserveTitles: [])
        }
        let script = dialect == .safari ? safariRestoreScript(groups) : chromiumRestoreScript(groups)
        let result = AppleScriptRunner().run(script, timeout: 8)
        guard result.succeeded else {
            return IntegrationRestore(
                fidelity: .partial,
                notes: [ScriptMessages.friendly(result.error ?? "Tabs could not be opened.", subject: "Saved tabs were not opened.")],
                createdWindowCount: 0,
                preserveTitles: []
            )
        }
        return IntegrationRestore(
            fidelity: .full,
            notes: ["Opened the saved tabs in new windows. Windows that were already open stay open unless they are minimized."],
            createdWindowCount: groups.count,
            preserveTitles: []
        )
    }

    private var chromiumCaptureScript: String {
        """
        tell application \(AppleScript.literal(applicationName))
            set delim to character id 31
            set output to ""
            repeat with w in windows
                set output to output & "WINDOW" & linefeed
                try
                    repeat with t in tabs of w
                        set tabTitle to ""
                        set tabURL to ""
                        try
                            set tabTitle to title of t as string
                        end try
                        try
                            set tabURL to URL of t as string
                        end try
                        set output to output & "TAB" & delim & tabTitle & delim & tabURL & linefeed
                    end repeat
                end try
            end repeat
            return output
        end tell
        """
    }

    private var safariCaptureScript: String {
        chromiumCaptureScript.replacingOccurrences(of: "tell application \(AppleScript.literal(applicationName))", with: "tell application \(AppleScript.literal(applicationName))")
    }

    private func chromiumRestoreScript(_ groups: [[RestorableResource]]) -> String {
        var lines = ["tell application \(AppleScript.literal(applicationName))", "activate"]
        for group in groups {
            guard let first = group.first else { continue }
            lines.append("make new window")
            lines.append("set URL of active tab of front window to \(AppleScript.literal(first.locator))")
            if group.count > 1 {
                lines.append("tell front window")
                for tab in group.dropFirst() {
                    lines.append("make new tab with properties {URL:\(AppleScript.literal(tab.locator))}")
                }
                lines.append("end tell")
            }
        }
        lines.append("end tell")
        return lines.joined(separator: "\n")
    }

    private func safariRestoreScript(_ groups: [[RestorableResource]]) -> String {
        var lines = ["tell application \(AppleScript.literal(applicationName))", "activate"]
        for group in groups {
            guard let first = group.first else { continue }
            lines.append("make new document with properties {URL:\(AppleScript.literal(first.locator))}")
            if group.count > 1 {
                lines.append("tell front window")
                for tab in group.dropFirst() {
                    lines.append("make new tab with properties {URL:\(AppleScript.literal(tab.locator))}")
                }
                lines.append("end tell")
            }
        }
        lines.append("end tell")
        return lines.joined(separator: "\n")
    }

    private static func tabGroups(in application: ApplicationState) -> [[RestorableResource]] {
        let tabs = application.resources
            .filter { $0.kind == .browserTab && ResourceValidator.isRestorableWebOrFileURL($0.locator) }
            .sorted { $0.index < $1.index }
        let grouped = Dictionary(grouping: tabs) { $0.windowID ?? application.windows.first?.id ?? UUID() }
        let order = application.windows.sorted { $0.zOrder < $1.zOrder }.map(\.id)
        var groups = order.compactMap { grouped[$0] }.filter { !$0.isEmpty }
        let known = Set(order)
        for (key, value) in grouped where !known.contains(key) && !value.isEmpty {
            groups.append(value)
        }
        if groups.isEmpty, !tabs.isEmpty {
            groups = [tabs]
        }
        return groups.reversed()
    }

    static func parse(_ output: String) -> [[(title: String, locator: String)]] {
        var groups: [[(title: String, locator: String)]] = []
        var current: [(title: String, locator: String)] = []
        var started = false
        for raw in output.split(separator: "\n", omittingEmptySubsequences: false) {
            let line = String(raw)
            if line == "WINDOW" {
                if started { groups.append(current) }
                current = []
                started = true
                continue
            }
            let parts = line.components(separatedBy: "\u{1f}")
            guard parts.count >= 3, parts[0] == "TAB" else { continue }
            if !started {
                started = true
            }
            current.append((title: parts[1], locator: parts[2]))
        }
        if started { groups.append(current) }
        return groups
    }

    private enum Dialect {
        case safari
        case chromium
        case firefox
        case unknown
    }

    private static func dialect(bundleIdentifier: String, applicationName: String) -> Dialect {
        let id = bundleIdentifier.lowercased()
        let name = applicationName.lowercased()
        if id == "com.apple.safari" || id == "com.apple.safaritechnologypreview" || name == "safari" || name == "safari technology preview" {
            return .safari
        }
        if id.hasPrefix("org.mozilla.firefox") || id == "org.mozilla.nightly" || name == "firefox" || name == "firefox nightly" {
            return .firefox
        }
        let chromiumIDs: Set<String> = [
            "com.google.chrome",
            "com.google.chrome.canary",
            "com.google.chrome.beta",
            "com.brave.browser",
            "com.microsoft.edgemac",
            "com.microsoft.edgemac.beta",
            "company.thebrowser.browser",
            "com.vivaldi.vivaldi",
            "com.operasoftware.opera",
            "org.chromium.chromium",
            "company.thebrowser.dia"
        ]
        let chromiumNames: Set<String> = ["google chrome", "brave browser", "microsoft edge", "arc", "vivaldi", "opera", "chromium", "dia"]
        if chromiumIDs.contains(id) || chromiumNames.contains(name) {
            return .chromium
        }
        return .unknown
    }
}
