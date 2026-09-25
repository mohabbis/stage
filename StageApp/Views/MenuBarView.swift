import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(StageStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stage")
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundStyle(StageTheme.ink)
            if store.workspaces.isEmpty {
                Text("No saved workspaces yet.")
                    .font(.system(size: 12))
                    .foregroundStyle(StageTheme.muted)
            } else {
                ForEach(store.workspaces.prefix(8)) { workspace in
                    Button(workspace.name) {
                        openStage()
                        store.requestRestore(id: workspace.id)
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(StageTheme.ink)
                }
            }
            Divider().overlay(StageTheme.line)
            Button("Save Workspace…") {
                openStage()
                store.requestCapture()
            }
            .buttonStyle(.plain)
            .foregroundStyle(StageTheme.amber)
            Button("Open Stage") { openStage() }
                .buttonStyle(.plain)
                .foregroundStyle(StageTheme.ink)
        }
        .padding(14)
        .frame(width: 280, alignment: .leading)
        .background(StageTheme.background)
    }

    private func openStage() {
        openWindow(id: "main")
        NSApp.activate()
    }
}
