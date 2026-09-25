import SwiftUI

struct WorkspaceGrid: View {
    var workspaces: [Workspace]
    var onOpen: (Workspace) -> Void
    var onRestore: (Workspace) -> Void

    private let columns = [GridItem(.adaptive(minimum: 320), spacing: 16)]

    var body: some View {
        ScrollView {
            if workspaces.isEmpty {
                empty
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(workspaces) { workspace in
                        WorkspaceCard(workspace: workspace) {
                            onOpen(workspace)
                        } onRestore: {
                            onRestore(workspace)
                        }
                    }
                }
                .padding(24)
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Save this desk.")
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundStyle(StageTheme.ink)
            Text("Stage remembers the applications, windows, tabs, and folders spread across your displays, then puts them back.")
                .font(.system(size: 15))
                .foregroundStyle(StageTheme.muted)
                .frame(maxWidth: 460, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(36)
    }
}
