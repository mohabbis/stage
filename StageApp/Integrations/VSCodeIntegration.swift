import Foundation

struct VSCodeIntegration: ApplicationIntegration {
    var applicationName: String
    var bundleIdentifier: String

    static func supports(bundleIdentifier: String, applicationName: String) -> Bool {
        let known: Set<String> = ["com.microsoft.VSCode", "com.microsoft.VSCodeInsiders", "com.cursor.Cursor"]
        if known.contains(bundleIdentifier) { return true }
        if bundleIdentifier.hasPrefix("com.todesktop.") && applicationName.localizedCaseInsensitiveContains("Cursor") {
            return true
        }
        return applicationName == "Cursor" || applicationName == "Visual Studio Code" || applicationName == "Code"
    }

    func capture(context: IntegrationContext) -> IntegrationCapture {
        let paths = storagePaths()
        var resources: [RestorableResource] = []
        for (index, path) in paths.enumerated() {
            let windowID = index < context.windows.count ? context.windows[index].window.id : nil
            resources.append(RestorableResource(
                id: UUID(),
                kind: .editorWorkspace,
                title: (path as NSString).lastPathComponent,
                locator: path,
                windowID: windowID,
                index: index,
                fidelity: .partial,
                note: "Restored as a project window. Unsaved editor state is not captured."
            ))
        }
        if context.windows.isEmpty && resources.isEmpty {
            return IntegrationCapture(resources: [], fidelity: .unsupported, notes: ["No editor windows were open."])
        }
        if resources.isEmpty {
            return IntegrationCapture(
                resources: [],
                fidelity: .partial,
                notes: ["Window layout was captured. Open projects could not be read."]
            )
        }
        return IntegrationCapture(
            resources: resources,
            fidelity: .partial,
            notes: ["Window layout and project folders. Unsaved files and cursor position are not captured."]
        )
    }

    func restore(application: ApplicationState) -> IntegrationRestore {
        let paths = application.resources
            .filter { $0.kind == .editorWorkspace && ResourceValidator.isSafeAbsolutePath($0.locator) }
            .sorted { $0.index < $1.index }
            .map(\.locator)
            .filter { FileManager.default.fileExists(atPath: $0) }
        guard !paths.isEmpty else {
            return IntegrationRestore(fidelity: .partial, notes: ["No saved project folder is still on disk."], createdWindowCount: 0, preserveTitles: [])
        }
        var opened = 0
        var notes: [String] = []
        for path in paths {
            let result = ApplicationLauncher.open(
                bundleIdentifier: bundleIdentifier,
                bundlePath: application.bundlePath,
                arguments: ["--new-window", path]
            )
            if result.running {
                opened += 1
            } else if let note = result.note {
                notes.append(note)
            }
        }
        if opened == 0 {
            return IntegrationRestore(fidelity: .partial, notes: notes.isEmpty ? ["The editor project could not be opened."] : notes, createdWindowCount: 0, preserveTitles: [])
        }
        return IntegrationRestore(
            fidelity: .partial,
            notes: ["Opened \(opened) saved \(opened == 1 ? "project" : "projects"). Unsaved editor state was not part of the snapshot."],
            createdWindowCount: opened,
            preserveTitles: []
        )
    }

    private func storagePaths() -> [String] {
        let folder: String
        switch bundleIdentifier {
        case "com.microsoft.VSCodeInsiders":
            folder = "Code - Insiders"
        case "com.cursor.Cursor":
            folder = "Cursor"
        case let id where id.hasPrefix("com.todesktop."):
            folder = "Cursor"
        default:
            folder = applicationName == "Cursor" ? "Cursor" : "Code"
        }
        let url = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/\(folder)/User/globalStorage/storage.json")
        guard let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let windowsState = root["windowsState"] else {
            return []
        }
        var found: [String] = []
        walk(windowsState, into: &found)
        var unique: [String] = []
        for path in found where !unique.contains(path) && FileManager.default.fileExists(atPath: path) {
            unique.append(path)
            if unique.count == 8 { break }
        }
        return unique
    }

    private func walk(_ value: Any, into paths: inout [String]) {
        if let dictionary = value as? [String: Any] {
            for (key, child) in dictionary {
                if key == "folder" || key == "workspace" || key == "file" {
                    if let string = child as? String {
                        append(string, to: &paths)
                    } else if let nested = child as? [String: Any] {
                        if let uri = nested["uri"] as? String ?? nested["external"] as? String {
                            append(uri, to: &paths)
                        }
                    }
                }
                walk(child, into: &paths)
            }
        } else if let array = value as? [Any] {
            for child in array { walk(child, into: &paths) }
        }
    }

    private func append(_ raw: String, to paths: inout [String]) {
        let path: String
        if let url = URL(string: raw), url.isFileURL {
            path = url.path
        } else if raw.hasPrefix("/") {
            path = raw
        } else {
            return
        }
        guard ResourceValidator.isSafeAbsolutePath(path) else { return }
        paths.append(path)
    }
}
