import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceDetailView: View {
    @Environment(StageStore.self) private var store
    var workspace: Workspace
    var onBack: () -> Void
    var onRestore: () -> Void
    @State private var draftName = ""
    @State private var isRenaming = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack {
                    Button("All workspaces", action: onBack)
                        .buttonStyle(StageButtonStyle(kind: .quiet))
                    Spacer()
                    Button("Export") { export() }
                        .buttonStyle(StageButtonStyle(kind: .quiet))
                    Button("Delete", role: .destructive) { store.delete(id: workspace.id); onBack() }
                        .buttonStyle(StageButtonStyle(kind: .danger))
                    Button("Restore", action: onRestore)
                        .buttonStyle(StageButtonStyle(kind: .primary))
                        .keyboardShortcut("r", modifiers: .command)
                }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    if isRenaming {
                        TextField("Name", text: $draftName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .onSubmit { commitRename() }
                    } else {
                        Text(workspace.name)
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundStyle(StageTheme.ink)
                        Button("Rename") {
                            draftName = workspace.name
                            isRenaming = true
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(StageTheme.amber)
                    }
                    Spacer()
                    FidelityBadge(fidelity: workspace.fidelity)
                }
                Text(meta)
                    .font(.system(size: 13))
                    .foregroundStyle(StageTheme.muted)
                if let warning = FrameMapper(source: workspace.displays, target: DisplayManager.current()).arrangementWarning {
                    Text(warning)
                        .font(.system(size: 13))
                        .foregroundStyle(StageTheme.amber)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(StageTheme.amber.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                WorkspacePreview(workspace: workspace)
                    .frame(height: 380)
                    .padding(16)
                    .background(StageTheme.sidebar)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                ForEach(workspace.applications) { app in
                    applicationRow(app)
                }
                if !workspace.limitations.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Limits")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(StageTheme.ink)
                        ForEach(workspace.limitations, id: \.self) { note in
                            Text(note)
                                .font(.system(size: 12))
                                .foregroundStyle(StageTheme.muted)
                        }
                    }
                }
            }
            .padding(28)
        }
    }

    private var meta: String {
        var parts = ["Saved \(workspace.updatedAt.formatted(date: .abbreviated, time: .shortened))"]
        if let restored = workspace.lastRestoredAt {
            parts.append("Restored \(restored.formatted(.relative(presentation: .named)))")
        }
        return parts.joined(separator: " · ")
    }

    private func applicationRow(_ app: ApplicationState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                AppIconView(bundlePath: app.bundlePath, name: app.name, size: 20)
                Text(app.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StageTheme.ink)
                Spacer()
                FidelityBadge(fidelity: app.fidelity)
            }
            if let note = app.note {
                Text(note)
                    .font(.system(size: 12))
                    .foregroundStyle(StageTheme.muted)
            }
            ForEach(app.windows) { window in
                let display = workspace.displays.first { $0.id == window.displayID }
                HStack {
                    Text(window.title)
                        .lineLimit(1)
                    Spacer()
                    if let display {
                        Text(LayoutPhrase.describe(window: window, display: display))
                    }
                }
                .font(.system(size: 12))
                .foregroundStyle(StageTheme.muted)
            }
            ForEach(app.resources) { resource in
                HStack {
                    Text(resource.kind.label)
                    Text(resource.title)
                        .lineLimit(1)
                    Spacer()
                    Text(resource.locator)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(StageTheme.ink.opacity(0.8))
            }
        }
        .padding(14)
        .background(StageTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func commitRename() {
        store.rename(id: workspace.id, to: draftName)
        isRenaming = false
    }

    private func export() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(workspace.name).stage.json"
        guard panel.runModal() == .OK, let url = panel.url, let data = try? StageJSON.prettyEncoder.encode(workspace) else { return }
        try? data.write(to: url)
    }
}
