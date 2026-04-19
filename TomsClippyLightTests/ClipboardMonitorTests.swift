import AppKit
import Foundation
import Testing
@testable import TomsClippyLight

@Suite("ClipboardMonitor")
@MainActor
struct ClipboardMonitorTests {
    private func makeMonitor(store: HistoryStore,
                             pasteboard: FakePasteboard,
                             ignorePasswords: Bool = true) -> ClipboardMonitor {
        ClipboardMonitor(
            pasteboard: pasteboard,
            store: store,
            ignorePasswordsProvider: { ignorePasswords }
        )
    }

    @Test("Plain text copy creates a text entry")
    func textEntry() {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard)

        pasteboard.setContent(types: [.string], strings: [.string: "hello"])
        monitor.poll()

        #expect(store.recent.count == 1)
        if case .text(let s) = store.recent.first?.content {
            #expect(s == "hello")
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("No poll-out if changeCount stayed the same")
    func noChange() {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard)

        pasteboard.setContent(types: [.string], strings: [.string: "hello"])
        monitor.poll()
        monitor.poll()  // changeCount unchanged
        #expect(store.recent.count == 1)
    }

    @Test("Concealed pasteboard type is ignored when setting enabled")
    func ignoreConcealedWhenEnabled() {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard, ignorePasswords: true)

        pasteboard.setContent(
            types: [.string, .concealed],
            strings: [.string: "topsecret"]
        )
        monitor.poll()

        #expect(store.recent.isEmpty)
    }

    @Test("Concealed is captured when ignorePasswords disabled")
    func captureConcealedWhenDisabled() {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard, ignorePasswords: false)

        pasteboard.setContent(
            types: [.string, .concealed],
            strings: [.string: "topsecret"]
        )
        monitor.poll()

        #expect(store.recent.count == 1)
    }

    @Test("RichText creates richText entry with plain text fallback")
    func richTextEntry() throws {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard)

        let attributed = NSAttributedString(string: "hello world")
        let rtfData = try attributed.data(
            from: NSRange(location: 0, length: attributed.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )

        pasteboard.setContent(
            types: [.rtf, .string],
            strings: [.string: "hello world"],
            data: [.rtf: rtfData]
        )
        monitor.poll()

        #expect(store.recent.count == 1)
        if case .richText(_, let plain) = store.recent.first?.content {
            #expect(plain == "hello world")
        } else {
            Issue.record("Expected richText content")
        }
    }

    @Test("File URL creates files entry")
    func filesEntry() {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard)

        let urls: [String] = ["file:///tmp/foo.txt", "file:///tmp/bar.txt"]
        let pls: [NSPasteboard.PasteboardType: Any] = [.fileURL: urls]
        pasteboard.setContent(types: [.fileURL], propertyLists: pls)
        monitor.poll()

        #expect(store.recent.count == 1)
        if case .files(let urls) = store.recent.first?.content {
            #expect(urls.count == 2)
            #expect(urls[0].lastPathComponent == "foo.txt")
        } else {
            Issue.record("Expected files content")
        }
    }

    @Test("Empty text is ignored")
    func emptyText() {
        let pasteboard = FakePasteboard()
        let store = HistoryStore(historySizeProvider: { 20 })
        let monitor = makeMonitor(store: store, pasteboard: pasteboard)

        pasteboard.setContent(types: [.string], strings: [.string: ""])
        monitor.poll()

        #expect(store.recent.isEmpty)
    }
}
