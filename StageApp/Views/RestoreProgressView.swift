import SwiftUI

@MainActor
@Observable
final class RestoreSession: Identifiable {
    let id = UUID()
    let workspaceID: UUID
    let workspaceName: String
    var events: [RestoreEvent] = []
    var isFinished = false

    init(workspace: Workspace) {
        workspaceID = workspace.id
        workspaceName = workspace.name
    }

    func apply(_ event: RestoreEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
        } else {
            events.append(event)
        }
        if event.id == "finished" {
            isFinished = true
        }
    }
}

struct RestoreProgressView: View {
    @Environment(\.dismiss) private var dismiss
    var session: RestoreSession

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Restoring \(session.workspaceName)")
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundStyle(StageTheme.ink)
            Text("Other applications are hidden, not quit. Stage reports anything it could not put back.")
                .font(.system(size: 13))
                .foregroundStyle(StageTheme.muted)
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(session.events) { event in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(color(for: event.state))
                                .frame(width: 8, height: 8)
                                .padding(.top, 5)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(StageTheme.ink)
                                if let detail = event.detail {
                                    Text(detail)
                                        .font(.system(size: 12))
                                        .foregroundStyle(StageTheme.muted)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            HStack {
                Spacer()
                Button(session.isFinished ? "Done" : "Running…") { dismiss() }
                    .buttonStyle(StageButtonStyle(kind: .primary))
                    .disabled(!session.isFinished)
            }
        }
        .padding(24)
        .frame(width: 520, height: 460)
        .background(StageTheme.background)
        .preferredColorScheme(.dark)
    }

    private func color(for state: RestoreEvent.RestoreStepState) -> Color {
        switch state {
        case .running: StageTheme.amber
        case .succeeded: StageTheme.full
        case .partial: StageTheme.partial
        case .failed: StageTheme.failed
        }
    }
}
