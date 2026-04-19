import AppKit
import Foundation

@MainActor
public final class MenuBuilder {
    private let historyStore: HistoryStore
    private let preferences: Preferences
    private let onSelectEntry: (ClipboardEntry) -> Void
    private let onOpenSettings: () -> Void
    private let onClearHistory: () -> Void
    private let onQuit: () -> Void

    public init(historyStore: HistoryStore,
                preferences: Preferences,
                onSelectEntry: @escaping (ClipboardEntry) -> Void,
                onOpenSettings: @escaping () -> Void,
                onClearHistory: @escaping () -> Void,
                onQuit: @escaping () -> Void) {
        self.historyStore = historyStore
        self.preferences = preferences
        self.onSelectEntry = onSelectEntry
        self.onOpenSettings = onOpenSettings
        self.onClearHistory = onClearHistory
        self.onQuit = onQuit
    }

    public func buildMenu() -> NSMenu {
        let menu = NSMenu()
        let target = MenuActionTarget(
            onSelectEntry: onSelectEntry,
            onOpenSettings: onOpenSettings,
            onClearHistory: onClearHistory,
            onQuit: onQuit
        )

        let settingsItem = NSMenuItem(
            title: L10n.menuSettings,
            action: #selector(MenuActionTarget.openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = target
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let entries = historyStore.topEntries(limit: preferences.historySize)
        if entries.isEmpty {
            let placeholder = NSMenuItem(title: L10n.menuEmpty, action: nil, keyEquivalent: "")
            placeholder.isEnabled = false
            menu.addItem(placeholder)
        } else {
            for (index, entry) in entries.enumerated() {
                let item = NSMenuItem(
                    title: displayTitle(for: entry),
                    action: #selector(MenuActionTarget.selectEntry(_:)),
                    keyEquivalent: index < 9 ? "\(index + 1)" : ""
                )
                item.target = target
                item.representedObject = entry
                if entry.isPinned {
                    item.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: nil)
                }
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())
        let clearItem = NSMenuItem(
            title: L10n.menuClear,
            action: #selector(MenuActionTarget.clearHistory(_:)),
            keyEquivalent: ""
        )
        clearItem.target = target
        menu.addItem(clearItem)

        menu.addItem(.separator())
        let quitItem = NSMenuItem(
            title: L10n.menuQuit,
            action: #selector(MenuActionTarget.quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = target
        menu.addItem(quitItem)

        objc_setAssociatedObject(menu, &MenuBuilder.targetKey, target, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return menu
    }

    nonisolated(unsafe) private static var targetKey: UInt8 = 0

    private func displayTitle(for entry: ClipboardEntry) -> String {
        let preview = entry.previewText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if preview.isEmpty {
            switch entry.content {
            case .image: return L10n.entryImage
            case .files(let urls):
                return urls.first?.lastPathComponent ?? L10n.entryFiles
            default: return L10n.entryEmpty
            }
        }
        return preview.count > 80 ? String(preview.prefix(80)) + "…" : preview
    }
}

private final class MenuActionTarget: NSObject {
    private let onSelectEntry: (ClipboardEntry) -> Void
    private let onOpenSettings: () -> Void
    private let onClearHistory: () -> Void
    private let onQuit: () -> Void

    init(onSelectEntry: @escaping (ClipboardEntry) -> Void,
         onOpenSettings: @escaping () -> Void,
         onClearHistory: @escaping () -> Void,
         onQuit: @escaping () -> Void) {
        self.onSelectEntry = onSelectEntry
        self.onOpenSettings = onOpenSettings
        self.onClearHistory = onClearHistory
        self.onQuit = onQuit
    }

    @objc func openSettings(_ sender: Any?) { onOpenSettings() }
    @objc func selectEntry(_ sender: NSMenuItem) {
        guard let entry = sender.representedObject as? ClipboardEntry else { return }
        onSelectEntry(entry)
    }
    @objc func clearHistory(_ sender: Any?) { onClearHistory() }
    @objc func quit(_ sender: Any?) { onQuit() }
}
