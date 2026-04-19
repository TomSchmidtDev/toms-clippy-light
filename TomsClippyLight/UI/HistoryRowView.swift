import AppKit
import SwiftUI

struct HistoryRowView: View {
    let entry: ClipboardEntry

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            icon
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                title
                    .lineLimit(2)
                    .font(.system(size: 13))
                metadata
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if entry.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var icon: some View {
        switch entry.content {
        case .image(let data):
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                Image(systemName: "photo").foregroundStyle(.secondary)
            }
        case .files:
            Image(systemName: "doc.fill").foregroundStyle(.secondary)
        case .richText:
            Image(systemName: "doc.richtext").foregroundStyle(.secondary)
        case .text:
            Image(systemName: "text.alignleft").foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var title: some View {
        switch entry.content {
        case .image:
            Text(L10n.entryImage).foregroundStyle(.secondary)
        case .files(let urls):
            Text(urls.map(\.lastPathComponent).joined(separator: ", "))
        case .text(let s):
            Text(s)
        case .richText(_, let plain):
            Text(plain)
        }
    }

    private var metadata: some View {
        Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
    }
}
