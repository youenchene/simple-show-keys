// Core: pure keystroke model. No AppKit here.
import Foundation

struct Modifiers: OptionSet, Hashable {
    let rawValue: Int
    static let ctrl = Modifiers(rawValue: 1)
    static let opt = Modifiers(rawValue: 2)
    static let shift = Modifiers(rawValue: 4)
    static let cmd = Modifiers(rawValue: 8)

    /// Canonical macOS order: ⌃ ⌥ ⇧ ⌘.
    static let ordered: [(Modifiers, name: String, symbol: String)] = [
        (.ctrl, "ctrl", "⌃"), (.opt, "opt", "⌥"), (.shift, "shift", "⇧"), (.cmd, "cmd", "⌘"),
    ]

    var symbols: String { Self.ordered.filter { contains($0.0) }.map(\.symbol).joined() }
    var names: [String] { Self.ordered.filter { contains($0.0) }.map(\.name) }
}

/// One key press. `key` is a layout-independent name: "x", "1", "return", "left", "f5".
struct Keystroke: Equatable {
    var key: String
    var isSpecial: Bool
    var mods: Modifiers
    /// What the press typed (shift/layout applied).
    var text: String

    enum Kind { case shortcut, special, text }

    var kind: Kind {
        if !mods.isDisjoint(with: [.ctrl, .opt, .cmd]) { return .shortcut }
        if key == "space" { return .text }
        if isSpecial { return mods.contains(.shift) ? .shortcut : .special }
        return .text
    }

    /// Display form: "⌃X", "↩", "a".
    var label: String {
        if kind == .text { return key == "space" ? "␣" : (text.isEmpty ? key : text) }
        return mods.symbols + Self.keyLabel(key)
    }

    /// Config form: "ctrl+x".
    var combo: String { (mods.names + [key]).joined(separator: "+") }

    static let specialLabels: [String: String] = [
        "return": "↩", "enter": "⌤", "tab": "⇥", "space": "␣", "delete": "⌫", "fwddelete": "⌦",
        "escape": "⎋", "left": "←", "right": "→", "up": "↑", "down": "↓", "home": "↖", "end": "↘",
        "pageup": "⇞", "pagedown": "⇟",
    ]

    static func keyLabel(_ key: String) -> String { specialLabels[key] ?? key.uppercased() }
}

enum Shortcut {
    /// Normalizes "Cmd+Shift+K" / "control + x" to the canonical "shift+cmd+k" form.
    /// Returns nil when there is no modifier or no key.
    static func normalize(_ raw: String) -> String? {
        let parts = raw.lowercased().split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2, let key = parts.last, !key.isEmpty else { return nil }
        var mods: Modifiers = []
        for p in parts.dropLast() {
            switch p {
            case "ctrl", "control", "⌃": mods.insert(.ctrl)
            case "opt", "alt", "option", "⌥": mods.insert(.opt)
            case "shift", "⇧": mods.insert(.shift)
            case "cmd", "command", "⌘": mods.insert(.cmd)
            default: return nil
            }
        }
        return (mods.names + [key]).joined(separator: "+")
    }

    /// "ctrl+x" → "⌃X".
    static func label(_ combo: String) -> String {
        let parts = combo.split(separator: "+").map(String.init)
        guard let key = parts.last else { return combo }
        let mods = Modifiers.ordered.filter { parts.dropLast().contains($0.name) }.map(\.symbol).joined()
        return mods + Keystroke.keyLabel(key)
    }
}
