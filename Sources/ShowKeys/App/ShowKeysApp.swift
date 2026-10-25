// Wiring: builds the core and the adapters and connects them.
import AppKit
import Combine

@main
enum ShowKeysApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // menu bar only, no Dock icon
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = SettingsStore()
    private let feed = KeyFeed()
    private var overlay: Overlay?
    private var monitor: KeyMonitor?
    private var menu: StatusMenu?
    private var settingsWindow: SettingsWindow?
    private var timer: Timer?
    private var bag: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        let overlay = Overlay(feed: feed, store: store)
        let settingsWindow = SettingsWindow(store: store)
        let menu = StatusMenu(store: store, openSettings: { settingsWindow.show() })

        let monitor = KeyMonitor { [weak self] stroke in
            guard let self else { return }
            overlay.moveToActiveScreen()
            feed.handle(stroke, settings: store.settings)
        }
        if !KeyMonitor.isTrusted { KeyMonitor.requestAccess() }
        monitor.start()

        // Expire items.
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.feed.prune() }
        }

        // Turning the overlay off clears it right away.
        store.$settings.map(\.enabled).removeDuplicates().sink { [weak self] on in
            if !on { self?.feed.clear() }
            self?.menu?.updateIcon()
        }.store(in: &bag)

        self.overlay = overlay
        self.settingsWindow = settingsWindow
        self.menu = menu
        self.monitor = monitor
    }
}
