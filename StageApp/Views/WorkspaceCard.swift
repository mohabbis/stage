import SwiftUI

struct WorkspaceCard: View {
    var workspace: Workspace
    var onOpen: () -> Void
    var onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            WorkspacePreview(workspace: workspace, compact: true)
                .frame(height: 168)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .onTapGesture(perform: onOpen)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workspace.name)
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundStyle(StageTheme.ink)
                    Text("\(workspace.applications.count) apps · \(workspace.displays.count) displays · \(workspace.updatedAt.formatted(.relative(presentation: .named)))")
                        .font(.system(size: 12))
                        .foregroundStyle(StageTheme.muted)
                }
                Spacer()
                FidelityBadge(fidelity: workspace.fidelity)
            }
            HStack {
                Button("Open", action: onOpen)
                    .buttonStyle(StageButtonStyle(kind: .quiet))
                Button("Restore", action: onRestore)
                    .buttonStyle(StageButtonStyle(kind: .primary))
            }
        }
        .padding(14)
        .background(StageTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(StageTheme.line, lineWidth: 1)
        )
    }
}
