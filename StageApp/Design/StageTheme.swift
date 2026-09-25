import SwiftUI

enum StageTheme {
    static let background = Color(red: 0.055, green: 0.054, blue: 0.047)
    static let sidebar = Color(red: 0.09, green: 0.086, blue: 0.078)
    static let elevated = Color(red: 0.13, green: 0.125, blue: 0.11)
    static let line = Color.white.opacity(0.08)
    static let ink = Color(red: 0.957, green: 0.945, blue: 0.918)
    static let muted = Color(red: 0.62, green: 0.60, blue: 0.55)
    static let amber = Color(red: 0.910, green: 0.627, blue: 0.290)
    static let full = Color(red: 0.55, green: 0.78, blue: 0.62)
    static let partial = Color(red: 0.910, green: 0.627, blue: 0.290)
    static let unsupported = Color(red: 0.55, green: 0.53, blue: 0.49)
    static let failed = Color(red: 0.82, green: 0.44, blue: 0.38)

    static func fidelity(_ fidelity: CaptureFidelity) -> Color {
        switch fidelity {
        case .full: full
        case .partial: partial
        case .unsupported: unsupported
        }
    }
}

struct StageButtonStyle: ButtonStyle {
    enum Kind { case primary, quiet, danger }
    var kind: Kind = .primary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }

    private var foreground: Color {
        switch kind {
        case .primary: Color.black.opacity(0.88)
        case .quiet: StageTheme.ink
        case .danger: StageTheme.failed
        }
    }

    private var background: Color {
        switch kind {
        case .primary: StageTheme.amber
        case .quiet: Color.white.opacity(0.06)
        case .danger: StageTheme.failed.opacity(0.12)
        }
    }
}

struct FidelityBadge: View {
    var fidelity: CaptureFidelity

    var body: some View {
        Text(fidelity.label)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(StageTheme.fidelity(fidelity))
            .background(StageTheme.fidelity(fidelity).opacity(0.14))
            .clipShape(Capsule())
    }
}

struct AppIconView: View {
    var bundlePath: String?
    var name: String
    var size: CGFloat = 16

    var body: some View {
        Image(nsImage: icon)
            .resizable()
            .frame(width: size, height: size)
    }

    private var icon: NSImage {
        if let bundlePath {
            return NSWorkspace.shared.icon(forFile: bundlePath)
        }
        return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: name) ?? NSImage()
    }
}
