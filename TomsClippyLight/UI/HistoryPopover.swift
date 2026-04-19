import SwiftUI

struct HistoryPopover: View {
    let historyStore: HistoryStore
    let preferences: Preferences
    let onSelect: (ClipboardEntry) -> Void
    let onDismiss: () -> Void

    @State private var searchText: String = ""
    @FocusState private var searchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            content
        }
        .frame(width: 360, height: 440)
        .onAppear { searchFocused = true }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(L10n.popoverSearchPlaceholder, text: $searchText)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .onSubmit(selectFirstMatch)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
    }

    private var content: some View {
        let (pinned, recent) = historyStore.searchResults(query: searchText)
        return Group {
            if pinned.isEmpty && recent.isEmpty {
                emptyState
            } else {
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
            .contentShape(Rectangle())
            .onTapGesture { onSelect(entry) }
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
    }

    private func selectFirstMatch() {
        let (pinned, recent) = historyStore.searchResults(query: searchText)
        if let first = pinned.first ?? recent.first {
            onSelect(first)
        }
    }
}
