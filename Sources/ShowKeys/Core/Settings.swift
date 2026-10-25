// Core: user settings and the proposed options. No AppKit here.

enum Size: String, Codable, CaseIterable, Identifiable {
    case small, medium, large, huge
    var id: String { rawValue }
    var name: String { self == .huge ? "Huge (recording)" : rawValue.capitalized }
    var points: Double { [.small: 18, .medium: 28, .large: 40, .huge: 60][self]! }
}

enum Position: String, Codable, CaseIterable, Identifiable {
    case bottomCenter, bottomLeft, bottomRight, topCenter, center
    var id: String { rawValue }
    var name: String {
        switch self {
        case .bottomCenter: "Bottom center"
        case .bottomLeft: "Bottom left"
        case .bottomRight: "Bottom right"
        case .topCenter: "Top center"
        case .center: "Center"
        }
    }
}

/// Colors are 0xRRGGBB; `opacity` applies to the background.
enum Theme: String, Codable, CaseIterable, Identifiable {
    case midnight, opencode, light, dracula, nord, solarized, sunset, matrix, contrast
    var id: String { rawValue }

    var name: String { self == .contrast ? "High contrast" : (self == .opencode ? "OpenCode" : rawValue.capitalized) }

    var colors: (background: UInt32, foreground: UInt32, accent: UInt32, opacity: Double) {
        switch self {
        case .midnight: (0x14161C, 0xFFFFFF, 0x7AA2F7, 0.88)
        case .opencode: (0x0A0A0A, 0xEEEEEE, 0xFAB283, 0.92)
        case .light: (0xF5F5F7, 0x1D1D1F, 0x0A84FF, 0.94)
        case .dracula: (0x282A36, 0xF8F8F2, 0xFF79C6, 0.92)
        case .nord: (0x2E3440, 0xECEFF4, 0x88C0D0, 0.92)
        case .solarized: (0x002B36, 0xEEE8D5, 0xB58900, 0.92)
        case .sunset: (0x2D1B3D, 0xFFE8D6, 0xFF7B54, 0.92)
        case .matrix: (0x000000, 0x00FF41, 0xD4FF00, 0.90)
        case .contrast: (0x000000, 0xFFFF00, 0x00FFFF, 1.0)
        }
    }
}

/// A shortcut after which the next key (the "key after") is shown with it, e.g. ctrl+x → n.
struct Leader: Codable, Equatable, Identifiable {
    var shortcut: String
    var enabled: Bool
    var id: String { shortcut }
}

struct Settings: Codable, Equatable {
    var enabled = true
    var showShortcuts = true
    var showSpecial = true
    var showText = true
    var uppercase = true
    var size = Size.medium
    var theme = Theme.midnight
    var position = Position.bottomCenter
    var seconds = 2.0
    var maxItems = 4
    var keyAfter = true
    var leaders = Settings.presets.map { Leader(shortcut: $0.shortcut, enabled: $0.shortcut == "ctrl+x") }

    static let presets: [(shortcut: String, hint: String)] = [
        ("ctrl+x", "opencode"),
        ("ctrl+b", "tmux"),
        ("ctrl+a", "screen"),
        ("ctrl+k", "VS Code"),
        ("cmd+k", "VS Code (macOS)"),
        ("ctrl+w", "vim windows"),
    ]

    static func hint(for shortcut: String) -> String? { presets.first { $0.shortcut == shortcut }?.hint }

    func isLeader(_ combo: String) -> Bool {
        keyAfter && leaders.contains { $0.enabled && $0.shortcut == combo }
    }

    func shows(_ kind: Keystroke.Kind) -> Bool {
        switch kind {
        case .shortcut: showShortcuts
        case .special: showSpecial
        case .text: showText
        }
    }
}
