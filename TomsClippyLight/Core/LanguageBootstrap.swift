import Foundation

enum LanguageBootstrap {
    static func applyIfNeeded(_ language: Preferences.Language) {
        switch language {
        case .auto:
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        case .english:
            UserDefaults.standard.set(["en"], forKey: "AppleLanguages")
        case .german:
            UserDefaults.standard.set(["de"], forKey: "AppleLanguages")
        }
    }
}
