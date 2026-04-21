import ApplicationServices
import AppKit
import Foundation

@MainActor
public final class Paster {
    private let pasteboard: PasteboardProtocol
    private let workspace: WorkspaceProtocol
    private let keyboard: KeyboardSimulating

    /// Injectable for unit tests. Production code uses the real AX check.
    private let textFocusChecker: @Sendable () -> Bool

    private var capturedFocus: CapturedFocus?

    public struct CapturedFocus: Equatable {
        public let bundleID: String?
        public let processID: pid_t?
        /// Whether a text input was focused in the previous app when we captured focus.
        /// Used to detect that Finder was in inline-rename mode before we stole focus.
        public let hadTextFocus: Bool
    }

    public init(
        pasteboard: PasteboardProtocol,
        workspace: WorkspaceProtocol,
        keyboard: KeyboardSimulating,
        /// Pass a custom checker in tests; leave nil for production (uses AX API).
        textFocusChecker: (@Sendable () -> Bool)? = nil
    ) {
        self.pasteboard = pasteboard
        self.workspace = workspace
        self.keyboard = keyboard
        self.textFocusChecker = textFocusChecker ?? { Paster.hasFocusedTextInput() }
    }

    // MARK: - Public API

    /// Snapshot the frontmost app and whether it has a focused text input.
    /// Must be called BEFORE our panel opens / steals focus.
    public func captureFocus() {
        capturedFocus = CapturedFocus(
            bundleID: workspace.frontmostAppBundleID,
            processID: workspace.frontmostAppProcessID,
            hadTextFocus: textFocusChecker()
        )
    }

    /// Full paste flow: write content → reactivate previous app → ⌘V.
    public func paste(_ entry: ClipboardEntry) {
        guard let focus = capturedFocus else { return }
        let activated = reactivate(focus: focus)
        guard activated else { return }

        Task { @MainActor [keyboard, workspace, pasteboard, textFocusChecker] in
            await waitForFocus(focus: focus, workspace: workspace)

            var textFocused = textFocusChecker()

            // ── Finder inline-rename restoration ──────────────────────────
            // When our panel opened, Finder's rename text field was cancelled
            // (our app stole key focus). Re-pressing Return re-enters rename
            // mode for the currently selected file in Finder.
            if !textFocused
                && focus.hadTextFocus
                && focus.bundleID == "com.apple.finder"
            {
                keyboard.postReturn()
                try? await Task.sleep(nanoseconds: 200_000_000)  // 200 ms
                textFocused = textFocusChecker()
            }

            // ── Choose pasteboard content ─────────────────────────────────
            // Files pasted into a text field → write the filename(s) as plain
            // text instead of a file-URL reference. This lets you paste the
            // name of a copied file into a rename field, Terminal, etc.
            if case .files(let urls) = entry.content, textFocused {
                let names = urls.map(\.lastPathComponent).joined(separator: ", ")
                let item = NSPasteboardItem()
                item.setString(names, forType: .string)
                pasteboard.clearAndWrite([item])
            } else {
                writeToPasteboardImpl(entry, using: pasteboard)
            }

            // ── Dispatch ⌘V ───────────────────────────────────────────────
            // For text/rich-text entries: skip ⌘V if there is no focused text
            // input (e.g. Finder file-browser after rename was cancelled and
            // couldn't be restored). The content stays on the pasteboard for
            // manual paste.
            if entry.isTextContent && !textFocused { return }
            keyboard.postCommandV()
        }
    }

    /// Write the entry to the shared pasteboard without triggering the paste flow.
    public func writeToPasteboard(_ entry: ClipboardEntry) {
        writeToPasteboardImpl(entry, using: pasteboard)
    }

    /// Post ⌘V directly (used by the local key monitor for Return/Enter key path).
    public func postCommandV() {
        keyboard.postCommandV()
    }

    // MARK: - Private helpers

    private func writeToPasteboardImpl(_ entry: ClipboardEntry, using pb: PasteboardProtocol) {
        let item = NSPasteboardItem()
        switch entry.content {
        case .text(let s):
            item.setString(s, forType: .string)
        case .richText(let rtf, let plain):
            item.setData(rtf, forType: .rtf)
            item.setString(plain, forType: .string)
        case .image(let data):
            item.setData(data, forType: .png)
        case .files(let urls):
            let strings = urls.map(\.absoluteString)
            item.setPropertyList(strings, forType: .fileURL)
            if let first = urls.first {
                item.setString(first.absoluteString, forType: .fileURL)
            }
        }
        pb.clearAndWrite([item])
    }

    private func waitForFocus(focus: CapturedFocus, workspace: WorkspaceProtocol) async {
        let deadline = 20  // up to 400 ms in 20 ms steps
        for _ in 0..<deadline {
            let pid = workspace.frontmostAppProcessID
            if let expected = focus.processID, pid == expected { return }
            if let expected = focus.bundleID, workspace.frontmostAppBundleID == expected { return }
            try? await Task.sleep(nanoseconds: 20_000_000)
        }
    }

    private func reactivate(focus: CapturedFocus) -> Bool {
        if let pid = focus.processID, workspace.activateApp(withProcessID: pid) { return true }
        if let bid = focus.bundleID,  workspace.activateApp(withBundleID: bid)  { return true }
        return false
    }

    /// Returns true when the system-wide focused UI element is a text input.
    /// Requires AXIsProcessTrusted() == true (same requirement as postCommandV).
    /// nonisolated so it can be captured as a @Sendable closure.
    nonisolated private static func hasFocusedTextInput() -> Bool {
        let systemElement = AXUIElementCreateSystemWide()
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            systemElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedRef
        ) == .success, let focused = focusedRef else { return false }

        // AXUIElement is a CF-backed opaque type; unsafeBitCast from CFTypeRef is
        // safe because kAXFocusedUIElementAttribute always returns an AXUIElement.
        let element = unsafeBitCast(focused, to: AXUIElement.self)

        var roleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXRoleAttribute as CFString,
            &roleRef
        ) == .success, let role = roleRef as? String else { return false }

        let textInputRoles: Set<String> = [
            kAXTextFieldRole as String,   // "AXTextField"
            kAXTextAreaRole as String,    // "AXTextArea"
            "AXComboBox",
            "AXSearchField",
        ]
        return textInputRoles.contains(role)
    }
}
