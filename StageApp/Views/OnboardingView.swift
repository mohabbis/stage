import AppKit
import SwiftUI

struct OnboardingView: View {
    @Environment(PermissionCenter.self) private var permissions

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Stage needs to see the desk.")
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundStyle(StageTheme.ink)
            Text("Accessibility is required to read and move windows. Screen Recording is optional and makes titles more reliable. The first time Stage reads Safari, Finder, or Terminal, macOS asks for Automation permission.")
                .font(.system(size: 14))
                .foregroundStyle(StageTheme.muted)
                .frame(maxWidth: 520, alignment: .leading)
            permissionRow(
                title: "Accessibility",
                granted: permissions.accessibility,
                detail: "Required to capture and restore window frames."
            ) {
                permissions.requestAccessibility()
                permissions.openAccessibilitySettings()
            }
            permissionRow(
                title: "Screen Recording",
                granted: permissions.screenRecording,
                detail: "Optional. Used when a window will not give up its title."
            ) {
                permissions.requestScreenRecording()
                permissions.openScreenRecordingSettings()
            }
            if permissions.needsAccessibilityRelaunch {
                Text("If Accessibility is already on for Stage, quit the app and open it again. macOS does not apply that permission to the copy that is already running.")
                    .font(.system(size: 12))
                    .foregroundStyle(StageTheme.amber)
                    .frame(maxWidth: 520, alignment: .leading)
            }
            Button("Continue") { permissions.dismissedOnboarding = true }
                .buttonStyle(StageButtonStyle(kind: permissions.accessibility ? .primary : .quiet))
        }
        .padding(36)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissions.refresh()
        }
    }

    private func permissionRow(title: String, granted: Bool, detail: String, action: @escaping () -> Void) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(StageTheme.ink)
                Text(granted ? "Granted" : detail)
                    .font(.system(size: 12))
                    .foregroundStyle(granted ? StageTheme.full : StageTheme.muted)
            }
            Spacer()
            if !granted {
                Button("Open Settings", action: action)
                    .buttonStyle(StageButtonStyle(kind: .quiet))
            }
        }
        .padding(14)
        .background(StageTheme.elevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(maxWidth: 560)
    }
}
