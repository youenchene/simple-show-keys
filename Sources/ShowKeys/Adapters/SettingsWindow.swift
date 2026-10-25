// Adapter: the settings window (SwiftUI form hosted in an NSWindow).
import AppKit
import SwiftUI

@MainActor
final class SettingsWindow {
    private var window: NSWindow?
    private let store: SettingsStore

    init(store: SettingsStore) { self.store = store }

    func show() {
        if window == nil {
            let w = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(store: store)))
            w.title = "Simple Show Keys Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.center()
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

/// Holds the "add leader" text field (kept out of @State on purpose: see AGENTS.md).
@MainActor
final class LeaderDraft: ObservableObject {
    @Published var text = ""
    @Published var invalid = false
}

struct SettingsView: View {
    @ObservedObject var store: SettingsStore
    @StateObject private var draft = LeaderDraft()

    var body: some View {
        Form {
            Section("Show") {
                Toggle("Show keystrokes", isOn: $store.settings.enabled)
                Toggle("Shortcuts  (⌘K, ⌃C, ⇧⇥)", isOn: $store.settings.showShortcuts)
                Toggle("Special keys  (↩ ⎋ ⌫ ← →)", isOn: $store.settings.showSpecial)
                Toggle("Typed text", isOn: $store.settings.showText)
                Toggle("Letters in upper case", isOn: $store.settings.uppercase)
            }

            Section("Look") {
                Picker("Size", selection: $store.settings.size) {
                    ForEach(Size.allCases) { Text($0.name).tag($0) }
                }
                Picker("Colors", selection: $store.settings.theme) {
                    ForEach(Theme.allCases) { t in
                        HStack {
                            Text(" ⌘K ")
                                .foregroundColor(Color(hex: t.colors.foreground))
                                .background(Color(hex: t.colors.background))
                            Text(t.name)
                        }.tag(t)
                    }
                }
                Picker("Position", selection: $store.settings.position) {
                    ForEach(Position.allCases) { Text($0.name).tag($0) }
                }
                Picker("Visible for", selection: $store.settings.seconds) {
                    ForEach([1.0, 1.5, 2, 3, 5], id: \.self) { Text("\($0.formatted()) s").tag($0) }
                }
                Stepper("Keys on screen: \(store.settings.maxItems)", value: $store.settings.maxItems, in: 1...10)
            }

            Section {
                Toggle("Show the key after a leader shortcut", isOn: $store.settings.keyAfter)
                ForEach($store.settings.leaders) { $leader in
                    HStack {
                        Toggle(isOn: $leader.enabled) {
                            Text(Shortcut.label(leader.shortcut)).font(.body.monospaced())
                            if let hint = Settings.hint(for: leader.shortcut) {
                                Text(hint).foregroundStyle(.secondary)
                            }
                        }
                        if Settings.hint(for: leader.shortcut) == nil {
                            Button(role: .destructive) { store.removeLeader(leader.shortcut) } label: {
                                Image(systemName: "minus.circle")
                            }.buttonStyle(.borderless)
                        }
                    }
                    .disabled(!store.settings.keyAfter)
                }
                HStack {
                    TextField("Add leader, e.g. ctrl+g", text: $draft.text)
                        .onSubmit(add)
                    Button("Add", action: add).disabled(draft.text.isEmpty)
                }
                .disabled(!store.settings.keyAfter)
                if draft.invalid {
                    Text("Use modifier+key: ctrl, opt, shift, cmd — e.g. cmd+shift+p")
                        .font(.caption).foregroundStyle(.red)
                }
            } header: {
                Text("Key after")
            } footer: {
                Text("After a leader, the next key is shown with it: ⌃X › N.")
                    .foregroundStyle(.secondary)
            }

            Section {
                HStack {
                    if KeyMonitor.isTrusted {
                        Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label("Accessibility access needed", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Spacer()
                        Button("Grant…") { KeyMonitor.requestAccess() }
                    }
                }
                Button("Reset to defaults") { store.reset() }
            }
        }
        .formStyle(.grouped)
        .frame(width: 440)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func add() {
        draft.invalid = !store.addLeader(draft.text)
        if !draft.invalid { draft.text = "" }
    }
}
