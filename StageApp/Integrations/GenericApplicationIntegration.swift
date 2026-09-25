import Foundation

struct GenericApplicationIntegration: ApplicationIntegration {
    func capture(context: IntegrationContext) -> IntegrationCapture {
        var resources: [RestorableResource] = []
        for item in context.windows {
            guard let locator = item.documentLocator, ResourceValidator.isRestorableFilePath(locator) else { continue }
            resources.append(RestorableResource(
                id: UUID(),
                kind: .document,
                title: (locator as NSString).lastPathComponent,
                locator: locator,
                windowID: item.window.id,
                index: 0,
                fidelity: .full,
                note: nil
            ))
        }
        if context.windows.isEmpty {
            return IntegrationCapture(resources: [], fidelity: .unsupported, notes: ["No windows could be read."])
        }
        let note = resources.isEmpty ? "Window layout." : "Window layout and open documents."
        return IntegrationCapture(resources: resources, fidelity: .full, notes: [note])
    }

    func restore(application: ApplicationState) -> IntegrationRestore {
        let documents = application.resources.filter {
            $0.kind == .document && ResourceValidator.isSafeAbsolutePath($0.locator)
        }
        guard !documents.isEmpty else {
            return IntegrationRestore(fidelity: .full, notes: [], createdWindowCount: 0, preserveTitles: [])
        }
        var notes: [String] = []
        var opened = 0
        for document in documents {
            let result = ApplicationLauncher.openFile(document.locator, bundleIdentifier: application.bundleIdentifier, bundlePath: application.bundlePath)
            if result.running {
                opened += 1
            } else if let note = result.note {
                notes.append("\(document.title): \(note)")
            }
        }
        let fidelity: CaptureFidelity = opened == documents.count ? .full : .partial
        if opened > 0 {
            notes.insert("Opened \(opened) saved \(opened == 1 ? "document" : "documents").", at: 0)
        }
        return IntegrationRestore(fidelity: fidelity, notes: notes, createdWindowCount: 0, preserveTitles: [])
    }
}
