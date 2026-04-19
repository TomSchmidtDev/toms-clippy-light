import Foundation

public final class PersistenceStore: @unchecked Sendable {
    public struct Snapshot: Codable, Sendable {
        public let pinned: [ClipboardEntry]
        public let recent: [ClipboardEntry]

        public init(pinned: [ClipboardEntry], recent: [ClipboardEntry]) {
            self.pinned = pinned
            self.recent = recent
        }
    }

    private let directory: URL
    private let fileManager: FileManager

    public init(directory: URL? = nil, fileManager: FileManager = .default) {
        if let directory {
            self.directory = directory
        } else {
            let appSupport = (try? fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.directory = appSupport.appendingPathComponent("TomsClippyLight", isDirectory: true)
        }
        self.fileManager = fileManager
        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    private var historyFile: URL {
        directory.appendingPathComponent("history.json")
    }

    public func save(_ snapshot: Snapshot) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: historyFile, options: .atomic)
        } catch {
            NSLog("[PersistenceStore] save failed: \(error)")
        }
    }

    public func load() -> Snapshot? {
        guard fileManager.fileExists(atPath: historyFile.path) else { return nil }
        do {
            let data = try Data(contentsOf: historyFile)
            return try JSONDecoder().decode(Snapshot.self, from: data)
        } catch {
            NSLog("[PersistenceStore] load failed: \(error)")
            return nil
        }
    }

    public func deleteAll() {
        try? fileManager.removeItem(at: historyFile)
    }
}
