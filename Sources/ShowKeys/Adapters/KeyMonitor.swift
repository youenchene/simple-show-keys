// Adapter: global key events (NSEvent) → Keystroke. Needs Accessibility permission.
import AppKit

@MainActor
final class KeyMonitor {
    private var monitors: [Any] = []
    private let onStroke: (Keystroke) -> Void

    init(onStroke: @escaping (Keystroke) -> Void) { self.onStroke = onStroke }

    static var isTrusted: Bool { AXIsProcessTrusted() }

    /// Shows the system "allow Accessibility" prompt.
    static func requestAccess() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)
    }

    /// Starts listening. Global events only arrive once Accessibility is granted, so we
    /// retry until then (granting does not require a relaunch).
    func start() {
        guard monitors.isEmpty else { return }
        guard Self.isTrusted else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.start() }
            return
        }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: { [weak self] e in
            MainActor.assumeIsolated { self?.forward(e) }
        }) { monitors.append(g) }
        if let l = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { [weak self] e in
            MainActor.assumeIsolated { self?.forward(e) }
            return e
        }) { monitors.append(l) }
    }

    private func forward(_ e: NSEvent) {
        if let stroke = Self.keystroke(from: e) { onStroke(stroke) }
    }

    static func keystroke(from e: NSEvent) -> Keystroke? {
        var mods: Modifiers = []
        let f = e.modifierFlags
        if f.contains(.control) { mods.insert(.ctrl) }
        if f.contains(.option) { mods.insert(.opt) }
        if f.contains(.shift) { mods.insert(.shift) }
        if f.contains(.command) { mods.insert(.cmd) }

        if let name = specialKeys[e.keyCode] {
            return Keystroke(key: name, isSpecial: name != "space", mods: mods, text: name == "space" ? " " : "")
        }
        guard let base = e.characters(byApplyingModifiers: [])?.lowercased(), !base.isEmpty else { return nil }
        return Keystroke(key: base, isSpecial: false, mods: mods, text: e.characters ?? "")
    }

    /// Virtual key codes (layout independent) for keys that type nothing printable.
    static let specialKeys: [UInt16: String] = [
        36: "return", 76: "enter", 48: "tab", 49: "space", 51: "delete", 117: "fwddelete",
        53: "escape", 123: "left", 124: "right", 125: "down", 126: "up",
        115: "home", 119: "end", 116: "pageup", 121: "pagedown",
        122: "f1", 120: "f2", 99: "f3", 118: "f4", 96: "f5", 97: "f6",
        98: "f7", 100: "f8", 101: "f9", 109: "f10", 103: "f11", 111: "f12",
    ]
}
