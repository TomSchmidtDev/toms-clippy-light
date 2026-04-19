import Foundation
import Observation

@Observable
@MainActor
public final class HistoryStore {
    public private(set) var recent: [ClipboardEntry] = []
    public private(set) var pinned: [ClipboardEntry] = []

    private let historySizeProvider: @MainActor () -> Int
    private let persistence: PersistenceStore?
    private var persistenceDebounceTask: Task<Void, Never>?

    public init(historySizeProvider: @escaping @MainActor () -> Int,
                persistence: PersistenceStore? = nil) {
        self.historySizeProvider = historySizeProvider
        self.persistence = persistence
    }

    public func add(_ entry: ClipboardEntry) {
        if let existingIndex = recent.firstIndex(where: { $0.contentKey == entry.contentKey }) {
            recent.remove(at: existingIndex)
        }
        if pinned.contains(where: { $0.contentKey == entry.contentKey }) {
            return
        }
        recent.insert(entry, at: 0)
        truncate()
        schedulePersistence()
    }

    public func clear() {
        recent.removeAll()
        schedulePersistence()
    }

    public func clearAll() {
        recent.removeAll()
        pinned.removeAll()
        schedulePersistence()
    }

    public func pin(_ entryID: ClipboardEntry.ID) {
        guard let index = recent.firstIndex(where: { $0.id == entryID }) else { return }
        var entry = recent.remove(at: index)
        entry.isPinned = true
        pinned.insert(entry, at: 0)
        schedulePersistence()
    }

    public func unpin(_ entryID: ClipboardEntry.ID) {
        guard let index = pinned.firstIndex(where: { $0.id == entryID }) else { return }
        var entry = pinned.remove(at: index)
        entry.isPinned = false
        recent.insert(entry, at: 0)
        truncate()
        schedulePersistence()
    }

    public func remove(_ entryID: ClipboardEntry.ID) {
        recent.removeAll { $0.id == entryID }
        pinned.removeAll { $0.id == entryID }
        schedulePersistence()
    }

    public func searchResults(query: String) -> (pinned: [ClipboardEntry], recent: [ClipboardEntry]) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return (pinned, recent) }
        let lowered = trimmed.lowercased()
        let matcher: (ClipboardEntry) -> Bool = { entry in
            entry.previewText.lowercased().contains(lowered)
        }
        return (pinned.filter(matcher), recent.filter(matcher))
    }

    public func topEntries(limit: Int) -> [ClipboardEntry] {
        Array(pinned.prefix(limit)) + Array(recent.prefix(max(0, limit - pinned.count)))
    }

    public func truncate() {
        let limit = max(1, min(100, historySizeProvider()))
        if recent.count > limit {
            recent.removeLast(recent.count - limit)
        }
    }

    public func loadFromDisk() {
        guard let persistence else { return }
        if let snapshot = persistence.load() {
            pinned = snapshot.pinned
            recent = snapshot.recent
            truncate()
        }
    }

    public func saveToDisk() {
        guard let persistence else { return }
        persistence.save(.init(pinned: pinned, recent: recent))
    }

    private func schedulePersistence() {
        guard persistence != nil else { return }
        persistenceDebounceTask?.cancel()
        persistenceDebounceTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.saveToDisk()
        }
    }
}
