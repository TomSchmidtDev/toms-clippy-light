import Foundation
import Testing
@testable import TomsClippyLight

@Suite("HistoryStore")
@MainActor
struct HistoryStoreTests {
    private func makeStore(size: Int = 20) -> HistoryStore {
        HistoryStore(historySizeProvider: { size })
    }

    @Test("New entry is inserted at the top")
    func insertAtTop() {
        let store = makeStore()
        store.add(ClipboardEntry(content: .text("a")))
        store.add(ClipboardEntry(content: .text("b")))
        #expect(store.recent.count == 2)
        #expect(store.recent.first?.previewText == "b")
    }

    @Test("Duplicate content moves the entry to the top instead of duplicating")
    func dedup() {
        let store = makeStore()
        store.add(ClipboardEntry(content: .text("a")))
        store.add(ClipboardEntry(content: .text("b")))
        store.add(ClipboardEntry(content: .text("a")))
        #expect(store.recent.count == 2)
        #expect(store.recent.map(\.previewText) == ["a", "b"])
    }

    @Test("Truncate enforces history size limit")
    func truncate() {
        let store = makeStore(size: 3)
        for i in 0..<5 {
            store.add(ClipboardEntry(content: .text("\(i)")))
        }
        #expect(store.recent.count == 3)
        #expect(store.recent.map(\.previewText) == ["4", "3", "2"])
    }

    @Test("Pinning moves an entry into the pinned list")
    func pinning() {
        let store = makeStore()
        let entry = ClipboardEntry(content: .text("keep"))
        store.add(entry)
        store.add(ClipboardEntry(content: .text("other")))
        store.pin(entry.id)
        #expect(store.pinned.count == 1)
        #expect(store.pinned.first?.isPinned == true)
        #expect(!store.recent.contains { $0.id == entry.id })
    }

    @Test("Pinned entries survive truncation")
    func pinnedSurviveTruncate() {
        let store = makeStore(size: 2)
        let pinned = ClipboardEntry(content: .text("pinned"))
        store.add(pinned)
        store.pin(pinned.id)
        for i in 0..<5 {
            store.add(ClipboardEntry(content: .text("n\(i)")))
        }
        #expect(store.pinned.contains { $0.contentKey == pinned.contentKey })
        #expect(store.recent.count == 2)
    }

    @Test("Adding an entry with same content as a pinned entry is skipped")
    func pinnedDedup() {
        let store = makeStore()
        let entry = ClipboardEntry(content: .text("hello"))
        store.add(entry)
        store.pin(entry.id)
        store.add(ClipboardEntry(content: .text("hello")))
        #expect(store.pinned.count == 1)
        #expect(store.recent.isEmpty)
    }

    @Test("Unpinning returns entry to recent")
    func unpin() {
        let store = makeStore()
        let entry = ClipboardEntry(content: .text("x"))
        store.add(entry)
        store.pin(entry.id)
        store.unpin(entry.id)
        #expect(store.pinned.isEmpty)
        #expect(store.recent.first?.id == entry.id)
        #expect(store.recent.first?.isPinned == false)
    }

    @Test("Clear removes recent entries but not pinned")
    func clear() {
        let store = makeStore()
        let entry = ClipboardEntry(content: .text("stay"))
        store.add(entry)
        store.pin(entry.id)
        store.add(ClipboardEntry(content: .text("go")))
        store.clear()
        #expect(store.recent.isEmpty)
        #expect(store.pinned.count == 1)
    }

    @Test("ClearAll removes both recent and pinned")
    func clearAll() {
        let store = makeStore()
        let entry = ClipboardEntry(content: .text("a"))
        store.add(entry)
        store.pin(entry.id)
        store.add(ClipboardEntry(content: .text("b")))
        store.clearAll()
        #expect(store.recent.isEmpty)
        #expect(store.pinned.isEmpty)
    }

    @Test("Search filters case-insensitively across preview text")
    func search() {
        let store = makeStore()
        store.add(ClipboardEntry(content: .text("Apple pie")))
        store.add(ClipboardEntry(content: .text("Banana split")))
        store.add(ClipboardEntry(content: .text("apple tart")))
        let results = store.searchResults(query: "apple")
        #expect(results.recent.count == 2)
    }

    @Test("TopEntries returns pinned first, then recent, up to limit")
    func topEntries() {
        let store = makeStore()
        let p = ClipboardEntry(content: .text("pinned"))
        store.add(p)
        store.pin(p.id)
        store.add(ClipboardEntry(content: .text("r1")))
        store.add(ClipboardEntry(content: .text("r2")))
        store.add(ClipboardEntry(content: .text("r3")))
        let top = store.topEntries(limit: 3)
        #expect(top.count == 3)
        #expect(top[0].contentKey == p.contentKey)
        #expect(top[1].previewText == "r3")
        #expect(top[2].previewText == "r2")
    }
}
