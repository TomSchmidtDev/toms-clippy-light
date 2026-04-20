import AppKit
import ApplicationServices
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
    private var historyPanel: NSPanel?
    private var menuBuilder: MenuBuilder!
    private var clickOutsideMonitor: Any?
    private var keyMonitor: Any?
    private var settingsWindowController: NSWindowController?

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
        setupHistoryPanel()
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

    private func setupHistoryPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 440),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.isMovable = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.hasShadow = true
        panel.backgroundColor = .clear
        panel.isOpaque = false

        let view = HistoryPopover(
            historyStore: historyStore,
            preferences: preferences,
            onSelect: { [weak self] entry in self?.handleEntrySelection(entry) },
            onDismiss: { [weak self] in self?.closeHistoryPanel() },
            onOpenSettings: { [weak self] in self?.openSettings() }
        )
        .background(.windowBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        panel.contentViewController = NSHostingController(rootView: view)
        historyPanel = panel
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            let menu = menuBuilder.buildMenu()
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            toggleHistoryPanel()
        }
    }

    private func toggleHistoryPanel() {
        if historyPanel?.isVisible == true {
            closeHistoryPanel()
        } else {
            showHistoryPanel()
        }
    }

    private func showHistoryPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window,
              let panel = historyPanel else { return }

        paster.captureFocus()

        let buttonRect = button.convert(button.bounds, to: nil)
        let screenRect = buttonWindow.convertToScreen(buttonRect)
        let panelWidth: CGFloat = 360
        let panelHeight: CGFloat = 440
        let x = min(screenRect.minX, NSScreen.main?.visibleFrame.maxX ?? screenRect.minX - panelWidth) - panelWidth + screenRect.width
        let y = screenRect.minY - panelHeight - 4
        panel.setFrame(NSRect(x: x, y: y, width: panelWidth, height: panelHeight), display: false)
        // Activate first so the window becomes key while the app is already active.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, let panel = self.historyPanel else { return }
            if !panel.frame.contains(NSEvent.mouseLocation) {
                self.closeHistoryPanel()
            }
        }

        // Local key monitor: intercepts ↑/↓ regardless of SwiftUI focus state.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.historyPanel?.isVisible == true else { return event }
            switch event.keyCode {
            case 125: // down arrow
                NotificationCenter.default.post(name: .historyMoveDown, object: nil)
                return nil
            case 126: // up arrow
                NotificationCenter.default.post(name: .historyMoveUp, object: nil)
                return nil
            case 36, 76: // Return / Enter (numpad)
                NotificationCenter.default.post(name: .historySelectCurrent, object: nil)
                return nil
            case 53: // Escape
                self.closeHistoryPanel()
                return nil
            default:
                return event
            }
        }
    }

    private func closeHistoryPanel() {
        historyPanel?.orderOut(nil)
        if let monitor = clickOutsideMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func handleEntrySelection(_ entry: ClipboardEntry) {
        closeHistoryPanel()
        paster.paste(entry)
    }

    private func openSettings() {
        if let wc = settingsWindowController, let window = wc.window, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView()
            .environment(preferences)
            .environment(historyStore)
        let window = NSWindow(contentViewController: NSHostingController(rootView: view))
        window.title = "Toms Clippy Light"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 480, height: 360))
        window.center()
        let wc = NSWindowController(window: window)
        settingsWindowController = wc
        wc.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func registerGlobalHotkey() {
        KeyboardShortcuts.onKeyUp(for: .showHistory) { [weak self] in
            guard let self else { return }
            self.toggleHistoryPanel()
        }
    }
}

private extension Int {
    func nonZeroOr(_ fallback: Int) -> Int { self == 0 ? fallback : self }
}

extension Notification.Name {
    static let historyMoveUp        = Notification.Name("historyMoveUp")
    static let historyMoveDown      = Notification.Name("historyMoveDown")
    static let historySelectCurrent = Notification.Name("historySelectCurrent")
}
