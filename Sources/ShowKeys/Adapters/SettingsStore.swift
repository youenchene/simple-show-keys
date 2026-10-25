// Adapter: settings persisted in UserDefaults.
import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    private static let key = "settings.v1"

    @Published var settings: Settings {
        didSet { save() }
    }

    init() {
        settings = Self.load() ?? Settings()
    }

    /// Stored values over defaults, so adding a setting doesn't reset the others.
    private static func load() -> Settings? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let stored = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let defaults = try? JSONSerialization.jsonObject(with: JSONEncoder().encode(Settings())) as? [String: Any],
              let merged = try? JSONSerialization.data(withJSONObject: defaults.merging(stored) { _, new in new })
        else { return nil }
        return try? JSONDecoder().decode(Settings.self, from: merged)
    }

    /// Adds a leader typed by the user ("ctrl+g"). Returns false if it does not parse.
    @discardableResult
    func addLeader(_ raw: String) -> Bool {
        guard let combo = Shortcut.normalize(raw) else { return false }
        if let i = settings.leaders.firstIndex(where: { $0.shortcut == combo }) {
            settings.leaders[i].enabled = true
        } else {
            settings.leaders.append(Leader(shortcut: combo, enabled: true))
        }
        return true
    }

    func removeLeader(_ combo: String) {
        settings.leaders.removeAll { $0.shortcut == combo }
    }

    func reset() { settings = Settings() }

    private func save() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
