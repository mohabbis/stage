import SwiftUI

@main
struct StageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = StageStore()
    @State private var permissions = PermissionCenter()

    var body: some Scene {
        Window("Stage", id: "main") {
            MainWindow()
                .environment(store)
                .environment(permissions)
                .onAppear {
                    WindowOpener.shared.openMain = {
                        // Replaced below once openWindow is available from the menu bar.
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: .stageCaptureRequested)) { _ in
                    store.requestCapture()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1140, height: 760)

        Settings {
            SettingsView()
                .environment(store)
                .environment(permissions)
        }

        MenuBarExtra {
            MenuBarRoot()
                .environment(store)
                .environment(permissions)
        } label: {
            Label("Stage", systemImage: "rectangle.split.2x1")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarRoot: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        MenuBarView()
            .onAppear {
                WindowOpener.shared.openMain = {
                    openWindow(id: "main")
                    NSApp.activate()
                }
            }
    }
}
