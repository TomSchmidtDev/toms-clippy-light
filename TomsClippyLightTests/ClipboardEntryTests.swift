import Foundation
import Testing
@testable import TomsClippyLight

@Suite("ClipboardEntry")
struct ClipboardEntryTests {
    @Test("Text entries with identical content share a contentKey")
    func textEntriesSameContentKey() {
        let a = ClipboardEntry(content: .text("hello"))
        let b = ClipboardEntry(content: .text("hello"))
        #expect(a.contentKey == b.contentKey)
        #expect(a.id != b.id)
    }

    @Test("Different text produces different contentKey")
    func textEntriesDifferentContentKey() {
        let a = ClipboardEntry(content: .text("hello"))
        let b = ClipboardEntry(content: .text("world"))
        #expect(a.contentKey != b.contentKey)
    }

    @Test("Image entries with same data share a contentKey")
    func imageEntriesShareKey() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])
        let a = ClipboardEntry(content: .image(pngData: data))
        let b = ClipboardEntry(content: .image(pngData: data))
        #expect(a.contentKey == b.contentKey)
    }

    @Test("File entries distinguish by URL")
    func fileEntries() {
        let a = ClipboardEntry(content: .files([URL(fileURLWithPath: "/tmp/a.txt")]))
        let b = ClipboardEntry(content: .files([URL(fileURLWithPath: "/tmp/b.txt")]))
        #expect(a.contentKey != b.contentKey)
    }

    @Test("Codable roundtrip preserves content")
    func codableRoundtrip() throws {
        let original = ClipboardEntry(content: .text("roundtrip"), isPinned: true)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClipboardEntry.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.isPinned == true)
        #expect(decoded.contentKey == original.contentKey)
    }

    @Test("previewText derives correctly from content kinds")
    func previewText() {
        #expect(ClipboardEntry(content: .text("hi")).previewText == "hi")
        #expect(ClipboardEntry(content: .richText(rtf: Data(), plain: "plain")).previewText == "plain")
        #expect(ClipboardEntry(content: .image(pngData: Data())).previewText.isEmpty)
        let files = ClipboardEntry(content: .files([URL(fileURLWithPath: "/tmp/a.txt"), URL(fileURLWithPath: "/tmp/b.txt")]))
        #expect(files.previewText == "a.txt, b.txt")
    }
}
