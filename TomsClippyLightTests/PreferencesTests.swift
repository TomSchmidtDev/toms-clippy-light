import Foundation
import Testing
@testable import TomsClippyLight

@Suite("Preferences")
@MainActor
struct PreferencesTests {
    private func makeDefaults() -> UserDefaults {
        let name = "prefs.test.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: name)!
        d.removePersistentDomain(forName: name)
        return d
    }

    @Test("Default values are correct for a fresh install")
    func defaults() {
        let prefs = Preferences(defaults: makeDefaults())
        #expect(prefs.historySize == 20)
        #expect(prefs.language == .auto)
        #expect(prefs.launchAtLogin == false)
        #expect(prefs.persistHistory == false)
        #expect(prefs.ignorePasswords == true)
    }

    @Test("History size is clamped into [1, 100]")
    func historySizeClamp() {
        let prefs = Preferences(defaults: makeDefaults())
        prefs.historySize = 0
        #expect(prefs.historySize == 1)

        prefs.historySize = 101
        #expect(prefs.historySize == 100)

        prefs.historySize = -50
        #expect(prefs.historySize == 1)

        prefs.historySize = 42
        #expect(prefs.historySize == 42)
    }

    @Test("Values persist through UserDefaults")
    func persistence() {
        let defaults = makeDefaults()
        do {
            let prefs = Preferences(defaults: defaults)
            prefs.historySize = 50
            prefs.language = .german
            prefs.launchAtLogin = true
            prefs.persistHistory = true
            prefs.ignorePasswords = false
        }
        let prefs2 = Preferences(defaults: defaults)
        #expect(prefs2.historySize == 50)
        #expect(prefs2.language == .german)
        #expect(prefs2.launchAtLogin == true)
        #expect(prefs2.persistHistory == true)
        #expect(prefs2.ignorePasswords == false)
    }

    @Test("Language enum returns correct locale code")
    func languageLocaleCode() {
        #expect(Preferences.Language.auto.localeCode == nil)
        #expect(Preferences.Language.english.localeCode == "en")
        #expect(Preferences.Language.german.localeCode == "de")
    }
}
