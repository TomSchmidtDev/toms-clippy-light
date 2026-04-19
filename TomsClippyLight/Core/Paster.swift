import AppKit
import Foundation

@MainActor
public final class Paster {
    private let pasteboard: PasteboardProtocol
    private let workspace: WorkspaceProtocol
    private let keyboard: KeyboardSimulating
    private var capturedFocus: CapturedFocus?

    public struct CapturedFocus: Equatable {
        public let bundleID: String?
        public let processID: pid_t?
    }

    public init(pasteboard: PasteboardProtocol,
                workspace: WorkspaceProtocol,
                keyboard: KeyboardSimulating) {
        self.pasteboard = pasteboard
        self.workspace = workspace
        self.keyboard = keyboard
    }

    public func captureFocus() {
        capturedFocus = CapturedFocus(
            bundleID: workspace.frontmostAppBundleID,
            processID: workspace.frontmostAppProcessID
        )
    }

    public func paste(_ entry: ClipboardEntry) {
        writeToPasteboard(entry)

        guard let focus = capturedFocus else {
            return
        }

        let activated = reactivate(focus: focus)
        guard activated else {
            return
        }

        Task { @MainActor [keyboard] in
            try? await Task.sleep(nanoseconds: 80_000_000)
            keyboard.postCommandV()
        }
    }

    public func writeToPasteboard(_ entry: ClipboardEntry) {
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
        pasteboard.clearAndWrite([item])
    }

    private func reactivate(focus: CapturedFocus) -> Bool {
        if let pid = focus.processID, workspace.activateApp(withProcessID: pid) {
            return true
        }
        if let bid = focus.bundleID, workspace.activateApp(withBundleID: bid) {
            return true
        }
        return false
    }
}
