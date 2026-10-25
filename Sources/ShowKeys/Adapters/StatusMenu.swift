// Adapter: the menu bar icon and its menu. This is the app's only permanent UI.
import AppKit

@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let store: SettingsStore
    private let openSettings: () -> Void

    init(store: SettingsStore, openSettings: @escaping () -> Void) {
        self.store = store
        self.openSettings = openSettings
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
        updateIcon()
    }

    func updateIcon() {
        let name = store.settings.enabled ? "keyboard.fill" : "keyboard"
        item.button?.image = NSImage(systemSymbolName: name, accessibilityDescription: "Simple Show Keys")
    }

    /// Rebuilt each time it opens, so it always reflects the current settings.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let s = store.settings
        if !KeyMonitor.isTrusted {
            menu.addItem(entry("⚠️ Grant Accessibility access…", #selector(grantAccess)))
            menu.addItem(.separator())
        }
        menu.addItem(entry("Show keystrokes", #selector(toggleEnabled), on: s.enabled, key: ""))
        menu.addItem(entry("Key after leader", #selector(toggleKeyAfter), on: s.keyAfter))
        menu.addItem(.separator())
        menu.addItem(entry("Settings…", #selector(settings), key: ","))
        menu.addItem(entry("Quit Simple Show Keys", #selector(quit), key: "q"))
    }

    private func entry(_ title: String, _ action: Selector, on: Bool? = nil, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        if let on { i.state = on ? .on : .off }
        return i
    }

    @objc private func toggleEnabled() {
        store.settings.enabled.toggle()
        updateIcon()
    }

    @objc private func toggleKeyAfter() { store.settings.keyAfter.toggle() }
    @objc private func settings() { openSettings() }
    @objc private func grantAccess() { KeyMonitor.requestAccess() }
    @objc private func quit() { NSApp.terminate(nil) }
}
