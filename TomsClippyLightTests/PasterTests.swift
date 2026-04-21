import AppKit
import Foundation
import Testing
@testable import TomsClippyLight

@Suite("Paster")
@MainActor
struct PasterTests {

    // MARK: - Helpers

    /// Default factory: textFocusChecker returns true (simulates a focused text field).
    private func makePaster(
        bundleID: String = "com.test.target",
        pid: pid_t = 7777,
        textFocused: Bool = true
    ) -> (Paster, FakePasteboard, FakeWorkspace, FakeKeyboardSimulator) {
        let pb = FakePasteboard()
        let ws = FakeWorkspace(bundleID: bundleID, pid: pid)
        let kb = FakeKeyboardSimulator()
        let paster = Paster(
            pasteboard: pb,
            workspace: ws,
            keyboard: kb,
            textFocusChecker: { textFocused }
        )
        return (paster, pb, ws, kb)
    }

    // MARK: - writeToPasteboard

    @Test("Writing text entry puts string on pasteboard")
    func writeText() {
        let (paster, pb, _, _) = makePaster()
        paster.writeToPasteboard(ClipboardEntry(content: .text("abc")))
        #expect(pb.clearAndWriteCalls == 1)
        #expect(pb.writtenItems.first?.string(forType: .string) == "abc")
    }

    @Test("Writing rich text includes both RTF and plain")
    func writeRichText() {
        let (paster, pb, _, _) = makePaster()
        let rtf = Data([0x7B, 0x72])
        paster.writeToPasteboard(ClipboardEntry(content: .richText(rtf: rtf, plain: "plain")))
        let item = pb.writtenItems.first
        #expect(item?.data(forType: .rtf) == rtf)
        #expect(item?.string(forType: .string) == "plain")
    }

    @Test("Writing image puts png data on pasteboard")
    func writeImage() {
        let (paster, pb, _, _) = makePaster()
        let png = Data([0x89, 0x50, 0x4E, 0x47])
        paster.writeToPasteboard(ClipboardEntry(content: .image(pngData: png)))
        #expect(pb.writtenItems.first?.data(forType: .png) == png)
    }

    // MARK: - captureFocus

    @Test("CaptureFocus snapshots current frontmost app")
    func captureFocus() {
        let (paster, _, ws, _) = makePaster()
        ws.frontmostAppBundleID = "com.apple.TextEdit"
        ws.frontmostAppProcessID = 9999
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("t")))
        #expect(ws.activatedProcessIDs.contains(9999))
    }

    // MARK: - reactivation

    @Test("Paste reactivates by PID first")
    func reactivateByPID() {
        let (paster, _, ws, _) = makePaster()
        ws.frontmostAppProcessID = 123
        ws.frontmostAppBundleID = "com.test.prev"
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("x")))
        #expect(ws.activatedProcessIDs == [123])
        #expect(ws.activatedBundleIDs.isEmpty)
    }

    @Test("Paste falls back to bundleID when PID activation fails")
    func reactivateFallback() {
        let (paster, _, ws, _) = makePaster()
        ws.frontmostAppProcessID = 123
        ws.frontmostAppBundleID = "com.test.prev"
        ws.activateProcessShouldSucceed = false
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("x")))
        #expect(ws.activatedBundleIDs == ["com.test.prev"])
    }

    // MARK: - ⌘V dispatching

    @Test("Paste posts ⌘V when a text field is focused (text entry)")
    func postsCommandVWithTextFocus() async {
        let (paster, _, _, kb) = makePaster(textFocused: true)
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("x")))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(kb.postCommandVCount == 1)
    }

    @Test("Paste skips ⌘V for text entry when no text field is focused")
    func skipsCommandVWithoutTextFocus() async {
        let (paster, _, _, kb) = makePaster(textFocused: false)
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("x")))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(kb.postCommandVCount == 0)
    }

    @Test("Paste always posts ⌘V for image entries regardless of text focus")
    func alwaysPostsCommandVForImage() async {
        let (paster, _, _, kb) = makePaster(textFocused: false)
        paster.captureFocus()
        let png = Data([0x89, 0x50, 0x4E, 0x47])
        paster.paste(ClipboardEntry(content: .image(pngData: png)))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(kb.postCommandVCount == 1)
    }

    // MARK: - Files → filename in text fields

    @Test("Files entry into text field writes filename as plain text")
    func filesEntryInTextFieldWritesFilename() async {
        let (paster, pb, _, kb) = makePaster(textFocused: true)
        paster.captureFocus()
        let url = URL(fileURLWithPath: "/tmp/Report.pdf")
        paster.paste(ClipboardEntry(content: .files([url])))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(pb.writtenItems.last?.string(forType: .string) == "Report.pdf")
        #expect(kb.postCommandVCount == 1)
    }

    @Test("Files entry without text field writes file URL (normal paste)")
    func filesEntryWithoutTextFieldWritesURL() async {
        let (paster, pb, _, kb) = makePaster(textFocused: false)
        paster.captureFocus()
        let url = URL(fileURLWithPath: "/tmp/Report.pdf")
        paster.paste(ClipboardEntry(content: .files([url])))
        try? await Task.sleep(nanoseconds: 200_000_000)
        // File URL on pasteboard, ⌘V dispatched (target handles it, e.g. Finder)
        #expect(pb.writtenItems.last?.string(forType: .fileURL) != nil)
        #expect(kb.postCommandVCount == 1)
    }

    @Test("Multiple files joined by comma in text field")
    func multipleFilesJoinedByComma() async {
        let (paster, pb, _, _) = makePaster(textFocused: true)
        paster.captureFocus()
        let urls = [
            URL(fileURLWithPath: "/tmp/a.txt"),
            URL(fileURLWithPath: "/tmp/b.txt"),
        ]
        paster.paste(ClipboardEntry(content: .files(urls)))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(pb.writtenItems.last?.string(forType: .string) == "a.txt, b.txt")
    }

    // MARK: - Finder rename restoration

    @Test("Finder rename: posts Return key when previous focus had a text field")
    func finderRenamePostsReturn() async {
        // Simulate: previous app was Finder with a text field focused,
        // but after reactivation there is NO text field (rename was cancelled).
        // Sequence: captureFocus → true; first paste check → false; after Return → true.
        final class FocusSequence: @unchecked Sendable {
            private var callCount = 0
            func next() -> Bool {
                callCount += 1
                return callCount == 1 || callCount >= 3   // true, false, true, true…
            }
        }
        let seq = FocusSequence()
        let pb = FakePasteboard()
        let ws = FakeWorkspace(bundleID: "com.apple.finder", pid: 42)
        let kb = FakeKeyboardSimulator()
        let paster = Paster(
            pasteboard: pb,
            workspace: ws,
            keyboard: kb,
            textFocusChecker: seq.next
        )
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("hello")))
        // Wait long enough for the 200 ms rename-restoration delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(kb.postReturnCount == 1)
        #expect(kb.postCommandVCount == 1)
    }

    @Test("Finder rename: does NOT post Return if previous focus had no text field")
    func finderNoReturnWhenNoTextFocusBefore() async {
        let (paster, _, ws, kb) = makePaster(bundleID: "com.apple.finder", textFocused: false)
        ws.frontmostAppBundleID = "com.apple.finder"
        paster.captureFocus()  // hadTextFocus = false (checker returns false)
        paster.paste(ClipboardEntry(content: .text("x")))
        try? await Task.sleep(nanoseconds: 500_000_000)
        #expect(kb.postReturnCount == 0)
    }
}
