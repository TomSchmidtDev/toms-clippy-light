import AppKit
import Foundation
@testable import TomsClippyLight

final class FakePasteboard: PasteboardProtocol, @unchecked Sendable {
    var changeCount: Int = 0
    private var _types: [NSPasteboard.PasteboardType] = []
    private var stringData: [NSPasteboard.PasteboardType: String] = [:]
    private var dataBlobs: [NSPasteboard.PasteboardType: Data] = [:]
    private var propertyLists: [NSPasteboard.PasteboardType: Any] = [:]

    private(set) var writtenItems: [NSPasteboardItem] = []
    private(set) var clearAndWriteCalls: Int = 0

    func setContent(types: [NSPasteboard.PasteboardType],
                    strings: [NSPasteboard.PasteboardType: String] = [:],
                    data: [NSPasteboard.PasteboardType: Data] = [:],
                    propertyLists: [NSPasteboard.PasteboardType: Any] = [:],
                    incrementChangeCount: Bool = true) {
        _types = types
        stringData = strings
        dataBlobs = data
        self.propertyLists = propertyLists
        if incrementChangeCount { changeCount += 1 }
    }

    func types() -> [NSPasteboard.PasteboardType] { _types }
    func data(forType type: NSPasteboard.PasteboardType) -> Data? { dataBlobs[type] }
    func string(forType type: NSPasteboard.PasteboardType) -> String? { stringData[type] }
    func propertyList(forType type: NSPasteboard.PasteboardType) -> Any? { propertyLists[type] }

    func clearAndWrite(_ items: [NSPasteboardItem]) {
        clearAndWriteCalls += 1
        writtenItems = items
        changeCount += 1
    }
}
