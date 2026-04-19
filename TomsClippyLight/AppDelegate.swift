import AppKit
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let preferences = Preferences()
    let historyStore: HistoryStore
    private let clipboardMonitor: ClipboardMonitor
    private let paster: Paster
    private let persistenceStore: PersistenceStore

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBuilder: MenuBuilder!
    private var eventMonitor: Any?

    override init() {
        let persistence = PersistenceStore()
        let store = HistoryStore(
            historySizeProvider: { UserDefaults.standard.integer(forKey: Preferences.Keys.historySize).nonZeroOr(20) },
            persistence: persistence
        )
        self.persistenceStore = persistence
        self.historyStore = store
        self.clipboardMonitor = ClipboardMonitor(
            pasteboard: SystemPasteboard(),
            store: store,
            ignorePasswordsProvider: { UserDefaults.standard.bool(forKey: Preferences.Keys.ignorePasswords) }
        )
        self.paster = Paster(
            pasteboard: SystemPasteboard(),
            workspace: SystemWorkspace(),
            keyboard: SystemKeyboardSimulator()
        )
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        LanguageBootstrap.applyIfNeeded(preferences.language)
        setupStatusItem()
        setupPopover()
        if preferences.persistHistory {
            historyStore.loadFromDisk()
        }
        clipboardMonitor.start()
        registerGlobalHotkey()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stop()
        if preferences.persistHistory {
            historyStore.saveToDisk()
        }
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Toms Clippy Light")
            button.image?.isTemplate = true
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        menuBuilder = MenuBuilder(
            historyStore: historyStore,
            preferences: preferences,
            onSelectEntry: { [weak self] entry in self?.handleEntrySelection(entry) },
            onOpenSettings: { [weak self] in self?.openSettings() },
            onClearHistory: { [weak self] in self?.historyStore.clear() },
            onQuit: { NSApp.terminate(nil) }
        )
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 360, height: 440)
        popover.contentViewController = NSHostingController(
            rootView: HistoryPopover(
                historyStore: historyStore,
                preferences: preferences,
                onSelect: { [weak self] entry in self?.handleEntrySelection(entry) },
                onDismiss: { [weak self] in self?.popover.performClose(nil) }
            )
        )
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = menuBuilder.buildMenu()
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            paster.captureFocus()
            togglePopover(sender)
        }
    }

    private func togglePopover(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    private func handleEntrySelection(_ entry: ClipboardEntry) {
        popover.performClose(nil)
        paster.paste(entry)
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    private func registerGlobalHotkey() {
        KeyboardShortcuts.onKeyUp(for: .showHistory) { [weak self] in
            guard let self else { return }
            guard let button = self.statusItem.button else { return }
            self.paster.captureFocus()
            self.togglePopover(button)
        }
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int { self == 0 ? fallback : self }
}
