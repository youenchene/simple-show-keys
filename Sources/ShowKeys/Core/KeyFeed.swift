// Core: turns keystrokes into the items shown on screen. No AppKit here.
import Combine
import Foundation

struct Item: Identifiable, Equatable {
    let id: Int
    /// Set when the item is a leader chord: "⌃X" then `label` is the key after.
    var leader: String?
    var label: String
    var isText: Bool
    var expires: Date
}

@MainActor
final class KeyFeed: ObservableObject {
    @Published private(set) var items: [Item] = []
    private var nextID = 0
    /// Leader waiting for its key after.
    private var pending: (id: Int, until: Date)?

    /// How long a leader waits for its key after.
    static let leaderTimeout: TimeInterval = 2

    func handle(_ stroke: Keystroke, settings: Settings, now: Date = Date()) {
        guard settings.enabled else { return }
        var stroke = stroke
        if settings.uppercase { stroke.text = stroke.text.uppercased() }
        prune(now: now)
        let expires = now.addingTimeInterval(settings.seconds)

        // Key after: always shown, attached to its leader.
        if let p = pending, now < p.until, let i = items.firstIndex(where: { $0.id == p.id }) {
            pending = nil
            items[i].label = stroke.label
            items[i].expires = expires
            return
        }
        pending = nil

        if stroke.kind == .shortcut, settings.isLeader(stroke.combo) {
            let id = append(Item(id: 0, leader: stroke.label, label: "", isText: false, expires: expires), max: settings.maxItems)
            pending = (id, now.addingTimeInterval(Self.leaderTimeout))
            return
        }

        guard settings.shows(stroke.kind) else { return }

        // Consecutive typing goes into one item: "hello world".
        if stroke.kind == .text, let last = items.last, last.isText {
            items[items.count - 1].label = String((last.label + stroke.label).suffix(24))
            items[items.count - 1].expires = expires
            return
        }
        append(Item(id: 0, leader: nil, label: stroke.label, isText: stroke.kind == .text, expires: expires),
               max: settings.maxItems)
    }

    /// True while a leader waits for its key after.
    func isPending(_ item: Item, now: Date = Date()) -> Bool {
        guard let p = pending else { return false }
        return p.id == item.id && now < p.until
    }

    func prune(now: Date = Date()) {
        if let p = pending, now >= p.until { pending = nil }
        if items.contains(where: { $0.expires <= now }) {
            items.removeAll { $0.expires <= now }
        }
    }

    func clear() {
        items = []
        pending = nil
    }

    @discardableResult
    private func append(_ item: Item, max: Int) -> Int {
        var item = item
        nextID += 1
        item = Item(id: nextID, leader: item.leader, label: item.label, isText: item.isText, expires: item.expires)
        items.append(item)
        if items.count > max { items.removeFirst(items.count - max) }
        return nextID
    }
}
