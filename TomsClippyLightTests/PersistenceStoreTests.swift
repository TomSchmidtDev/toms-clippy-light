import Foundation
import Testing
@testable import TomsClippyLight

@Suite("PersistenceStore")
struct PersistenceStoreTests {
    private func makeTempDirectory() -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("TomsClippyLightTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Save then load preserves snapshot")
    func roundtrip() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = PersistenceStore(directory: dir)
        let pinned = [ClipboardEntry(content: .text("pinned"), isPinned: true)]
        let recent = [
            ClipboardEntry(content: .text("a")),
            ClipboardEntry(content: .files([URL(fileURLWithPath: "/tmp/demo.txt")]))
        ]
        store.save(.init(pinned: pinned, recent: recent))

        let loaded = store.load()
        #expect(loaded?.pinned.count == 1)
        #expect(loaded?.recent.count == 2)
        #expect(loaded?.pinned.first?.isPinned == true)
    }

    @Test("Load returns nil if no file exists")
    func loadNilIfMissing() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = PersistenceStore(directory: dir)
        #expect(store.load() == nil)
    }

    @Test("DeleteAll removes the history file")
    func deleteAll() {
        let dir = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = PersistenceStore(directory: dir)
        store.save(.init(pinned: [], recent: [ClipboardEntry(content: .text("x"))]))
        #expect(store.load() != nil)
        store.deleteAll()
        #expect(store.load() == nil)
    }
}
