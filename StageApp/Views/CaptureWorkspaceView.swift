import SwiftUI

struct CaptureWorkspaceView: View {
    @Environment(StageStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var snapshot: Workspace?
    @State private var isCapturing = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Save workspace")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(StageTheme.ink)
            Text("Stage records this Space: windows, displays, and the tabs, folders, or directories it can actually read.")
                .font(.system(size: 13))
                .foregroundStyle(StageTheme.muted)
            TextField("ECON 402", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 16))
                .padding(12)
                .background(StageTheme.elevated)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            Group {
                if isCapturing {
                    ProgressView("Reading the desk…")
                        .controlSize(.small)
                        .tint(StageTheme.amber)
                } else if let snapshot {
                    WorkspacePreview(workspace: snapshot, compact: true)
                        .frame(height: 220)
                    HStack {
                        FidelityBadge(fidelity: snapshot.fidelity)
                        Text("\(snapshot.applications.count) apps · \(snapshot.windowCount) windows")
                            .font(.system(size: 12))
                            .foregroundStyle(StageTheme.muted)
                    }
                    ForEach(snapshot.limitations, id: \.self) { note in
                        Text(note)
                            .font(.system(size: 12))
                            .foregroundStyle(StageTheme.muted)
                    }
                }
            }
            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(StageButtonStyle(kind: .quiet))
                Spacer()
                Button("Save") { save() }
                    .buttonStyle(StageButtonStyle(kind: .primary))
                    .disabled(isCapturing || snapshot == nil || snapshot?.applications.isEmpty == true || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(width: 560)
        .background(StageTheme.background)
        .preferredColorScheme(.dark)
        .task { await capture() }
    }

    private func capture() async {
        isCapturing = true
        let captured = await Task.detached(priority: .userInitiated) {
            WorkspaceCaptureService.capture(named: "Untitled")
        }.value
        snapshot = captured
        isCapturing = false
    }

    private func save() {
        guard var snapshot else { return }
        snapshot.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        store.save(snapshot)
        dismiss()
    }
}
