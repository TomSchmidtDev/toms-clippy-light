import AppKit
import Foundation

public protocol PasteboardProtocol: AnyObject, Sendable {
    var changeCount: Int { get }
    func types() -> [NSPasteboard.PasteboardType]
    func data(forType type: NSPasteboard.PasteboardType) -> Data?
    func string(forType type: NSPasteboard.PasteboardType) -> String?
    func propertyList(forType type: NSPasteboard.PasteboardType) -> Any?
    func clearAndWrite(_ items: [NSPasteboardItem])
}

public final class SystemPasteboard: PasteboardProtocol, @unchecked Sendable {
    private let pasteboard: NSPasteboard

    public init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    public var changeCount: Int { pasteboard.changeCount }

    public func types() -> [NSPasteboard.PasteboardType] {
        pasteboard.types ?? []
    }

    public func data(forType type: NSPasteboard.PasteboardType) -> Data? {
        pasteboard.data(forType: type)
    }

    public func string(forType type: NSPasteboard.PasteboardType) -> String? {
        pasteboard.string(forType: type)
    }

    public func propertyList(forType type: NSPasteboard.PasteboardType) -> Any? {
        pasteboard.propertyList(forType: type)
    }

    public func clearAndWrite(_ items: [NSPasteboardItem]) {
        pasteboard.clearContents()
        pasteboard.writeObjects(items)
    }
}

public extension NSPasteboard.PasteboardType {
    static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
}
