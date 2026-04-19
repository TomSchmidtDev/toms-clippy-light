import Foundation
import Observation

@Observable
@MainActor
public final class Preferences {
    public enum Keys {
        public static let historySize = "historySize"
        public static let language = "language"
        public static let launchAtLogin = "launchAtLogin"
        public static let persistHistory = "persistHistory"
        public static let ignorePasswords = "ignorePasswords"
    }

    public enum Language: String, CaseIterable, Codable, Sendable {
        case auto
        case english = "en"
        case german = "de"

        public var localeCode: String? {
            switch self {
            case .auto: return nil
            case .english: return "en"
            case .german: return "de"
            }
        }
    }

    private let defaults: UserDefaults

    public var historySize: Int {
        didSet {
            let clamped = max(1, min(100, historySize))
            if clamped != historySize {
                historySize = clamped
            } else {
                defaults.set(historySize, forKey: Keys.historySize)
            }
        }
    }

    public var language: Language {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    public var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    public var persistHistory: Bool {
        didSet { defaults.set(persistHistory, forKey: Keys.persistHistory) }
    }

    public var ignorePasswords: Bool {
        didSet { defaults.set(ignorePasswords, forKey: Keys.ignorePasswords) }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedSize = defaults.object(forKey: Keys.historySize) as? Int ?? 20
        self.historySize = max(1, min(100, storedSize))
        self.language = Language(rawValue: defaults.string(forKey: Keys.language) ?? "") ?? .auto
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.persistHistory = (defaults.object(forKey: Keys.persistHistory) as? Bool) ?? false
        self.ignorePasswords = (defaults.object(forKey: Keys.ignorePasswords) as? Bool) ?? true
    }
}
