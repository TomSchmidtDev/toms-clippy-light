import AppKit
import Foundation

@MainActor
public final class ClipboardMonitor {
    private let pasteboard: PasteboardProtocol
    private let store: HistoryStore
    private let ignorePasswordsProvider: @MainActor () -> Bool
    private var lastChangeCount: Int
    private var timer: Timer?
    private let pollInterval: TimeInterval

    public init(pasteboard: PasteboardProtocol,
                store: HistoryStore,
                ignorePasswordsProvider: @escaping @MainActor () -> Bool,
                pollInterval: TimeInterval = 0.4) {
        self.pasteboard = pasteboard
        self.store = store
        self.ignorePasswordsProvider = ignorePasswordsProvider
        self.lastChangeCount = pasteboard.changeCount
        self.pollInterval = pollInterval
    }

    public func start() {
        stop()
        let timer = Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }

    public func poll() {
        let current = pasteboard.changeCount
        guard current != lastChangeCount else { return }
        lastChangeCount = current

        let types = pasteboard.types()

        if ignorePasswordsProvider(), types.contains(.concealed) {
            return
        }

        guard let entry = buildEntry(types: types) else { return }
        store.add(entry)
    }

    private func buildEntry(types: [NSPasteboard.PasteboardType]) -> ClipboardEntry? {
        if types.contains(.fileURL) {
            if let array = pasteboard.propertyList(forType: .fileURL) as? [String] {
                let urls = array.compactMap { URL(string: $0) }
                if !urls.isEmpty {
                    return ClipboardEntry(content: .files(urls))
                }
            }
            if let single = pasteboard.string(forType: .fileURL), let url = URL(string: single) {
                return ClipboardEntry(content: .files([url]))
            }
        }

        if types.contains(.tiff) || types.contains(.png) {
            let data: Data?
            if types.contains(.png) {
                data = pasteboard.data(forType: .png)
            } else if let tiff = pasteboard.data(forType: .tiff), let pngData = ClipboardMonitor.pngData(fromTIFF: tiff) {
                data = pngData
            } else {
                data = nil
            }
            if let data {
                return ClipboardEntry(content: .image(pngData: data))
            }
        }

        if types.contains(.rtf), let rtf = pasteboard.data(forType: .rtf) {
            let plain = pasteboard.string(forType: .string) ?? ClipboardMonitor.plainText(fromRTF: rtf) ?? ""
            if !plain.isEmpty {
                return ClipboardEntry(content: .richText(rtf: rtf, plain: plain))
            }
        }

        if types.contains(.string), let text = pasteboard.string(forType: .string), !text.isEmpty {
            return ClipboardEntry(content: .text(text))
        }

        return nil
    }

    nonisolated static func pngData(fromTIFF tiff: Data) -> Data? {
        guard let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    nonisolated static func plainText(fromRTF rtf: Data) -> String? {
        guard let attr = try? NSAttributedString(
            data: rtf,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) else { return nil }
        return attr.string
    }
}
