import SwiftUI

struct SettingsView: View {
    @Environment(Preferences.self) private var preferences
    @Environment(HistoryStore.self) private var historyStore

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label(L10n.settingsTabGeneral, systemImage: "gearshape") }
            ShortcutSettingsTab()
                .tabItem { Label(L10n.settingsTabShortcut, systemImage: "keyboard") }
            AboutTab()
                .tabItem { Label(L10n.settingsTabAbout, systemImage: "info.circle") }
        }
        .frame(width: 480, height: 360)
        .padding()
    }
}

#Preview {
    SettingsView()
        .environment(Preferences(defaults: UserDefaults(suiteName: "preview")!))
        .environment(HistoryStore(historySizeProvider: { 20 }))
}
