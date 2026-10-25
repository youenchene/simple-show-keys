// Adapter: the transparent click-through panel that draws the keystrokes.
import AppKit
import SwiftUI

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double(hex >> 16 & 0xFF) / 255,
                  green: Double(hex >> 8 & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}

extension Position {
    var alignment: Alignment {
        switch self {
        case .bottomCenter: .bottom
        case .bottomLeft: .bottomLeading
        case .bottomRight: .bottomTrailing
        case .topCenter: .top
        case .center: .center
        }
    }
}

@MainActor
final class Overlay {
    private let panel: NSPanel

    init(feed: KeyFeed, store: SettingsStore) {
        panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.contentView = NSHostingView(rootView: OverlayView(feed: feed, store: store))
        moveToActiveScreen()
        panel.orderFrontRegardless()
    }

    /// Follows the screen under the mouse.
    func moveToActiveScreen() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let frame = screen?.visibleFrame, panel.frame != frame {
            panel.setFrame(frame, display: true)
        }
    }
}

struct OverlayView: View {
    @ObservedObject var feed: KeyFeed
    @ObservedObject var store: SettingsStore

    var body: some View {
        let s = store.settings
        let c = s.theme.colors
        HStack(spacing: s.size.points * 0.35) {
            ForEach(feed.items) { item in
                HStack(spacing: s.size.points * 0.3) {
                    if let leader = item.leader {
                        Text(leader).foregroundColor(Color(hex: c.accent))
                        Text("›").foregroundColor(Color(hex: c.accent).opacity(0.7))
                        Text(item.label.isEmpty ? "…" : item.label)
                            .opacity(feed.isPending(item) ? 0.4 : 1)
                    } else {
                        Text(item.label)
                    }
                }
                .foregroundColor(Color(hex: c.foreground))
                .font(.system(size: s.size.points, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .padding(.horizontal, s.size.points * 0.55)
                .padding(.vertical, s.size.points * 0.3)
                .background(
                    RoundedRectangle(cornerRadius: s.size.points * 0.4, style: .continuous)
                        .fill(Color(hex: c.background, opacity: c.opacity))
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .animation(.easeOut(duration: 0.15), value: feed.items)
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: s.position.alignment)
    }
}
