import AppKit
import SwiftUI

struct AboutTab: View {
    private var version: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading) {
                    Text("Toms Clippy Light").font(.title2).fontWeight(.semibold)
                    Text("\(L10n.aboutVersion) \(version)").font(.caption).foregroundStyle(.secondary)
                }
            }

            Divider()

            Link(destination: URL(string: "https://github.com/tomschmidtdev/toms-clippy-light")!) {
                Label(L10n.aboutGithub, systemImage: "link")
            }

            Text(L10n.aboutUnquarantineHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Spacer()
        }
        .padding()
    }
}
