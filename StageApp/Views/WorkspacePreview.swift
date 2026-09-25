import SwiftUI

struct WorkspacePreview: View {
    var workspace: Workspace
    var compact: Bool = false

    var body: some View {
        GeometryReader { geo in
            let union = DisplayLocator.union(of: workspace.displays)
            let scale = min(geo.size.width / max(union.width, 1), geo.size.height / max(union.height, 1))
            let fitted = CGSize(width: union.width * scale, height: union.height * scale)
            ZStack(alignment: .topLeading) {
                ForEach(workspace.displays) { display in
                    displayBezel(display, scale: scale)
                        .offset(
                            x: (display.frame.x - union.x) * scale,
                            y: (display.frame.y - union.y) * scale
                        )
                }
            }
            .frame(width: fitted.width, height: fitted.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func displayBezel(_ display: DisplayState, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: compact ? 8 : 12, style: .continuous)
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: compact ? 8 : 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                windowLayer(on: display)
                    .padding(compact ? 6 : 10)
            }
            .frame(width: display.frame.width * scale, height: display.frame.height * scale)
            if !compact {
                Text(display.name)
                    .font(.system(size: 11))
                    .foregroundStyle(StageTheme.muted)
                    .lineLimit(1)
            }
        }
    }

    private func windowLayer(on display: DisplayState) -> some View {
        GeometryReader { proxy in
            let pairs = workspace.windows(on: display).sorted { $0.1.zOrder > $1.1.zOrder }
            ForEach(Array(pairs.enumerated()), id: \.element.1.id) { _, pair in
                let window = pair.1
                let relX = (window.frame.x - display.frame.x) / max(display.frame.width, 1)
                let relY = (window.frame.y - display.frame.y) / max(display.frame.height, 1)
                let relW = window.frame.width / max(display.frame.width, 1)
                let relH = window.frame.height / max(display.frame.height, 1)
                windowTile(app: pair.0, window: window, display: display)
                    .frame(
                        width: max(relW * proxy.size.width, 8),
                        height: max(relH * proxy.size.height, 8)
                    )
                    .offset(x: relX * proxy.size.width, y: relY * proxy.size.height)
            }
        }
    }

    private func windowTile(app: ApplicationState, window: WindowState, display: DisplayState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                AppIconView(bundlePath: app.bundlePath, name: app.name, size: compact ? 8 : 12)
                if !compact {
                    Text(window.title)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .foregroundStyle(StageTheme.ink)
                }
            }
            if !compact {
                Text(LayoutPhrase.describe(window: window, display: display))
                    .font(.system(size: 9))
                    .foregroundStyle(StageTheme.muted)
                    .lineLimit(1)
            }
        }
        .padding(compact ? 3 : 6)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .help("\(app.name) · \(LayoutPhrase.describe(window: window, display: display))")
    }
}
