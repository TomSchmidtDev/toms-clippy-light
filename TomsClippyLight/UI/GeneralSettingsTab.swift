import SwiftUI

struct GeneralSettingsTab: View {
    @Environment(Preferences.self) private var preferences
    @State private var launchAtLoginService: LaunchAtLoginService = SystemLaunchAtLoginService()
    @State private var launchAtLoginError: String?

    var body: some View {
        @Bindable var prefs = preferences
        Form {
            Toggle(L10n.settingsLaunchAtLogin, isOn: Binding(
                get: { prefs.launchAtLogin },
                set: { newValue in
                    prefs.launchAtLogin = newValue
                    do {
                        try launchAtLoginService.setEnabled(newValue)
                        launchAtLoginError = nil
                    } catch {
                        launchAtLoginError = error.localizedDescription
                    }
                }
            ))
            if let launchAtLoginError {
                Text(launchAtLoginError).font(.caption).foregroundStyle(.red)
            }

            Picker(L10n.settingsLanguage, selection: $prefs.language) {
                Text(L10n.settingsLanguageAuto).tag(Preferences.Language.auto)
                Text(L10n.settingsLanguageEnglish).tag(Preferences.Language.english)
                Text(L10n.settingsLanguageGerman).tag(Preferences.Language.german)
            }
            Text(L10n.settingsLanguageRestartHint)
                .font(.caption)
                .foregroundStyle(.secondary)

            Stepper(
                "\(L10n.settingsHistorySize): \(prefs.historySize)",
                value: $prefs.historySize,
                in: 1...100
            )

            Toggle(L10n.settingsPersistHistory, isOn: $prefs.persistHistory)
            Toggle(L10n.settingsIgnorePasswords, isOn: $prefs.ignorePasswords)
        }
        .formStyle(.grouped)
        .onAppear {
            prefs.launchAtLogin = launchAtLoginService.isEnabled
        }
    }
}
