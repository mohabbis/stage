import AppKit
import SwiftUI

struct MainWindow: View {
    @Environment(StageStore.self) private var store
    @Environment(PermissionCenter.self) private var permissions
    @AppStorage("hideUnrelatedApplications") private var hideUnrelated = true
    @AppStorage("minimizeUnmatchedWindows") private var minimizeUnmatched = true
    @State private var selection: UUID?
    @State private var query = ""
    @State private var showingCapture = false
    @State private var restoreSession: RestoreSession?

    private var selected: Workspace? {
        store.workspaces.first { $0.id == selection }
    }

    private var filtered: [Workspace] {
        store.workspaces.filter { $0.matches(query: query) }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Rectangle().fill(StageTheme.line).frame(height: 1)
            if !permissions.accessibility && permissions.dismissedOnboarding {
                Text("Accessibility is off. Stage can launch apps, but it cannot move windows until you grant it in Settings.")
                    .font(.system(size: 12))
                    .foregroundStyle(StageTheme.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(StageTheme.amber.opacity(0.08))
            }
            Group {
                if !permissions.accessibility && store.workspaces.isEmpty && !permissions.dismissedOnboarding {
                    OnboardingView()
                } else if let selected {
                    WorkspaceDetailView(workspace: selected, onBack: { selection = nil }, onRestore: { startRestore(selected) })
                } else {
                    WorkspaceGrid(workspaces: filtered, onOpen: { selection = $0.id }, onRestore: startRestore)
                }
            }
        }
        .background(StageTheme.background)
        .preferredColorScheme(.dark)
        .frame(minWidth: 960, minHeight: 640)
        .sheet(isPresented: $showingCapture) { CaptureWorkspaceView() }
        .sheet(item: $restoreSession) { session in
            RestoreProgressView(session: session)
        }
        .onAppear { consumePending() }
        .onChange(of: store.pendingCapture) { _, _ in consumePending() }
        .onChange(of: store.pendingRestoreID) { _, _ in consumePending() }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.refresh()
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Text("Stage")
                .font(.system(size: 20, weight: .regular, design: .serif))
                .foregroundStyle(StageTheme.ink)
            TextField("Search workspaces", text: $query)
                .textFieldStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .frame(maxWidth: 240)
            Spacer()
            Button("Save Workspace") { showingCapture = true }
                .buttonStyle(StageButtonStyle(kind: .primary))
                .keyboardShortcut("s", modifiers: .command)
        }
        .padding(.leading, 78)
        .padding(.trailing, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
    }

    private func consumePending() {
        if store.pendingCapture {
            store.pendingCapture = false
            showingCapture = true
        }
        if let id = store.pendingRestoreID {
            store.pendingRestoreID = nil
            selection = id
            if let workspace = store.workspaces.first(where: { $0.id == id }) {
                startRestore(workspace)
            }
        }
    }

    private func startRestore(_ workspace: Workspace) {
        let session = RestoreSession(workspace: workspace)
        restoreSession = session
        store.markRestored(id: workspace.id)
        Task {
            let stream = WorkspaceRestoreService.restore(workspace, hideUnrelated: hideUnrelated, minimizeUnmatched: minimizeUnmatched)
            for await event in stream {
                session.apply(event)
            }
        }
    }
}
