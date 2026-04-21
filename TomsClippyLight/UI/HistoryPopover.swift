import ApplicationServices
import SwiftUI

struct HistoryPopover: View {
    let historyStore: HistoryStore
    let preferences: Preferences
    let onSelect: (ClipboardEntry) -> Void
    let onDismiss: () -> Void
    let onOpenSettings: () -> Void

    @State private var searchText: String = ""
    @State private var selectedID: ClipboardEntry.ID? = nil
    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    @State private var pollTimer: Timer?

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            content
            if !isAccessibilityTrusted {
                accessibilityBanner
            }
        }
        .frame(width: 360, height: 440)
        .onAppear(perform: panelDidAppear)
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyMoveUp)) { _ in
            moveSelection(by: -1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .historyMoveDown)) { _ in
            moveSelection(by: 1)
        }
        .onReceive(NotificationCenter.default.publisher(for: .historySelectCurrent)) { _ in
            selectCurrent()
        }
    }

    private func panelDidAppear() {
        searchText = ""
        selectedID = nil
        isAccessibilityTrusted = AXIsProcessTrusted()
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                isAccessibilityTrusted = AXIsProcessTrusted()
            }
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(L10n.popoverSearchPlaceholder, text: $searchText)
                .textFieldStyle(.plain)
                .onSubmit(selectCurrent)
            if !searchText.isEmpty {
                Button(action: { searchText = ""; selectedID = nil }) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .onChange(of: searchText) { selectedID = nil }
    }

    @ViewBuilder
    private var content: some View {
        let (pinned, recent) = historyStore.searchResults(query: searchText)
        if pinned.isEmpty && recent.isEmpty {
            emptyState
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if !pinned.isEmpty {
                            sectionHeader(L10n.popoverPinnedSection)
                            ForEach(pinned) { entry in
                                row(entry, isPinned: true)
                            }
                        }
                        if !recent.isEmpty {
                            sectionHeader(L10n.popoverRecentSection)
                            ForEach(recent) { entry in
                                row(entry, isPinned: false)
                            }
                        }
                    }
                }
                .onChange(of: selectedID) {
                    if let id = selectedID { proxy.scrollTo(id) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
            Text(L10n.popoverEmpty)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }

    private var accessibilityBanner: some View {
        Button(action: { onDismiss(); onOpenSettings() }) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                Text(L10n.popoverAccessibilityHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.orange.opacity(0.08))
        }
        .buttonStyle(.plain)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func row(_ entry: ClipboardEntry, isPinned: Bool) -> some View {
        HistoryRowView(entry: entry)
            .background(entry.id == selectedID ? Color.accentColor.opacity(0.15) : Color.clear)
            .contentShape(Rectangle())
            .onTapGesture { onSelect(entry) }
            .onHover { hovering in
                if hovering { selectedID = entry.id }
            }
            .contextMenu {
                if isPinned {
                    Button(L10n.popoverActionUnpin) { historyStore.unpin(entry.id) }
                } else {
                    Button(L10n.popoverActionPin) { historyStore.pin(entry.id) }
                }
                Button(L10n.popoverActionDelete, role: .destructive) {
                    historyStore.remove(entry.id)
                }
            }
            .id(entry.id)
    }

    private func allEntries() -> [ClipboardEntry] {
        let (pinned, recent) = historyStore.searchResults(query: searchText)
        return pinned + recent
    }

    private func moveSelection(by delta: Int) {
        let all = allEntries()
        guard !all.isEmpty else { return }
        if let current = selectedID, let idx = all.firstIndex(where: { $0.id == current }) {
            selectedID = all[max(0, min(all.count - 1, idx + delta))].id
        } else {
            selectedID = delta > 0 ? all.first?.id : all.last?.id
        }
    }

    private func selectCurrent() {
        let all = allEntries()
        if let id = selectedID, let entry = all.first(where: { $0.id == id }) {
            onSelect(entry)
        } else if let first = all.first {
            onSelect(first)
        }
    }
}
