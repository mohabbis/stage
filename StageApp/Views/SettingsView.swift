import ServiceManagement
import SwiftUI

struct SettingsView: View {
    @Environment(PermissionCenter.self) private var permissions
    @AppStorage("hideUnrelatedApplications") private var hideUnrelated = true
    @AppStorage("minimizeUnmatchedWindows") private var minimizeUnmatched = true
    @State private var loginError: String?

    var body: some View {
        Form {
            Section("Permissions") {
                LabeledContent("Accessibility") {
                    Text(permissions.accessibility ? "Granted" : "Required")
                    if !permissions.accessibility {
                        Button("Grant") {
                            permissions.requestAccessibility()
                            permissions.openAccessibilitySettings()
                        }
                    }
                }
                LabeledContent("Screen Recording") {
                    Text(permissions.screenRecording ? "Granted" : "Optional")
                    if !permissions.screenRecording {
                        Button("Grant") {
                            permissions.requestScreenRecording()
                            permissions.openScreenRecordingSettings()
                        }
                    }
                }
            }
            Section("Restore") {
                Toggle("Hide unrelated applications", isOn: $hideUnrelated)
                Toggle("Minimize windows that are not part of the workspace", isOn: $minimizeUnmatched)
                Text("Stage never quits the applications it did not save.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Section("General") {
                Toggle("Open at login", isOn: launchBinding)
                if let loginError {
                    Text(loginError).foregroundStyle(.red)
                }
            }
            Section("About") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0")
                Text("Workspaces stay in Application Support on this Mac.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 520, height: 460)
        .onAppear { permissions.refresh() }
    }

    private var launchBinding: Binding<Bool> {
        Binding {
            SMAppService.mainApp.status == .enabled
        } set: { enabled in
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                loginError = nil
            } catch {
                loginError = error.localizedDescription
            }
        }
    }
}

@MainActor
@Observable
final class PermissionCenter {
    var accessibility = false
    var screenRecording = false
    var dismissedOnboarding = UserDefaults.standard.bool(forKey: "dismissedOnboarding") {
        didSet { UserDefaults.standard.set(dismissedOnboarding, forKey: "dismissedOnboarding") }
    }

    init() { refresh() }

    func refresh() {
        accessibility = AccessibilityManager.isTrusted
        screenRecording = AccessibilityManager.hasScreenRecording
    }

    func requestAccessibility() {
        _ = AccessibilityManager.requestAccessibility()
        refresh()
    }

    func requestScreenRecording() {
        _ = AccessibilityManager.requestScreenRecording()
        refresh()
    }

    func openAccessibilitySettings() { AccessibilityManager.openAccessibilitySettings() }
    func openScreenRecordingSettings() { AccessibilityManager.openScreenRecordingSettings() }
}
