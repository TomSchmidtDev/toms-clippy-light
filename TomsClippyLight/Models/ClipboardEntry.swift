import AppKit
import Foundation

public struct ClipboardEntry: Identifiable, Hashable, Codable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public var isPinned: Bool
    public let content: Content

    public init(content: Content,
                timestamp: Date = Date(),
                isPinned: Bool = false,
                id: UUID = UUID()) {
        self.id = id
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.content = content
    }

    public enum Content: Hashable, Codable, Sendable {
        case text(String)
        case richText(rtf: Data, plain: String)
        case image(pngData: Data)
        case files([URL])
    }

    public var contentKey: String {
        switch content {
        case .text(let s):
            return "t:\(s)"
        case .richText(_, let plain):
            return "r:\(plain)"
        case .image(let data):
            return "i:\(data.sha256Hex())"
        case .files(let urls):
            return "f:\(urls.map(\.path).joined(separator: "|"))"
        }
    }

    public var previewText: String {
        switch content {
        case .text(let s):
            return s
        case .richText(_, let plain):
            return plain
        case .image:
            return ""
        case .files(let urls):
            return urls.map(\.lastPathComponent).joined(separator: ", ")
        }
    }

    public var kindLabel: String {
        switch content {
        case .text, .richText: return "text"
        case .image: return "image"
        case .files: return "files"
        }
    }

    /// True for text and rich-text entries, false for images and file references.
    /// Used to decide whether ⌘V makes sense in the target app.
    public var isTextContent: Bool {
        switch content {
        case .text, .richText: return true
        case .image, .files: return false
        }
    }
}

import CryptoKit

private extension Data {
    func sha256Hex() -> String {
        SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}
