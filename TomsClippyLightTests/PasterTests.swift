import AppKit
import Foundation
import Testing
@testable import TomsClippyLight

@Suite("Paster")
@MainActor
struct PasterTests {
    private func makePaster() -> (Paster, FakePasteboard, FakeWorkspace, FakeKeyboardSimulator) {
        let pb = FakePasteboard()
        let ws = FakeWorkspace(bundleID: "com.test.target", pid: 7777)
        let kb = FakeKeyboardSimulator()
        return (Paster(pasteboard: pb, workspace: ws, keyboard: kb), pb, ws, kb)
    }

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
        let rtf = Data([0x7B, 0x72])  // any non-empty rtf payload
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

    @Test("CaptureFocus snapshots current frontmost app")
    func captureFocus() {
        let (paster, _, ws, _) = makePaster()
        ws.frontmostAppBundleID = "com.apple.TextEdit"
        ws.frontmostAppProcessID = 9999
        paster.captureFocus()
        // Indirect check: paste will use snapshot
        paster.paste(ClipboardEntry(content: .text("t")))
        #expect(ws.activatedProcessIDs.contains(9999))
    }

    @Test("Paste reactivates by PID first, then bundleID")
    func reactivatePreference() {
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

    @Test("Paste always posts Cmd+V; caller is responsible for checking accessibility trust")
    func alwaysPostsCommandV() async {
        let (paster, _, _, kb) = makePaster()
        paster.captureFocus()
        paster.paste(ClipboardEntry(content: .text("x")))
        try? await Task.sleep(nanoseconds: 200_000_000)
        #expect(kb.postCommandVCount == 1)
        #expect(kb.trustRequestCount == 0)
    }
}
