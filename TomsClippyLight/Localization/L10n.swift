import Foundation
import SwiftUI

enum L10n {
    static var menuSettings: String { NSLocalizedString("menu.settings", value: "Settings…", comment: "Menu: open settings") }
    static var menuEmpty: String { NSLocalizedString("menu.empty", value: "No history yet", comment: "Menu: empty placeholder") }
    static var menuClear: String { NSLocalizedString("menu.clear", value: "Clear History", comment: "Menu: clear history") }
    static var menuQuit: String { NSLocalizedString("menu.quit", value: "Quit", comment: "Menu: quit app") }

    static var entryImage: String { NSLocalizedString("entry.image", value: "Image", comment: "Image entry label") }
    static var entryFiles: String { NSLocalizedString("entry.files", value: "Files", comment: "Files entry label") }
    static var entryEmpty: String { NSLocalizedString("entry.empty", value: "(empty)", comment: "Empty entry label") }

    static var settingsTabGeneral: String { NSLocalizedString("settings.tab.general", value: "General", comment: "Settings tab") }
    static var settingsTabShortcut: String { NSLocalizedString("settings.tab.shortcut", value: "Shortcut", comment: "Settings tab") }
    static var settingsTabAbout: String { NSLocalizedString("settings.tab.about", value: "About", comment: "Settings tab") }

    static var settingsLaunchAtLogin: String { NSLocalizedString("settings.launchAtLogin", value: "Launch at login", comment: "Settings label") }
    static var settingsLanguage: String { NSLocalizedString("settings.language", value: "Language", comment: "Settings label") }
    static var settingsLanguageAuto: String { NSLocalizedString("settings.language.auto", value: "Automatic (System)", comment: "Settings label") }
    static var settingsLanguageEnglish: String { NSLocalizedString("settings.language.english", value: "English", comment: "Settings label") }
    static var settingsLanguageGerman: String { NSLocalizedString("settings.language.german", value: "German", comment: "Settings label") }
    static var settingsHistorySize: String { NSLocalizedString("settings.historySize", value: "History size", comment: "Settings label") }
    static var settingsPersistHistory: String { NSLocalizedString("settings.persistHistory", value: "Persist history between restarts", comment: "Settings label") }
    static var settingsIgnorePasswords: String { NSLocalizedString("settings.ignorePasswords", value: "Ignore passwords (1Password, Safari AutoFill, …)", comment: "Settings label") }
    static var settingsShortcutLabel: String { NSLocalizedString("settings.shortcut.label", value: "Show history:", comment: "Settings label") }
    static var settingsAccessibilityTitle: String { NSLocalizedString("settings.accessibility.title", value: "Accessibility permission", comment: "Settings label") }
    static var settingsAccessibilityOk: String { NSLocalizedString("settings.accessibility.ok", value: "Granted — auto-paste is ready.", comment: "Settings label") }
    static var settingsAccessibilityMissing: String { NSLocalizedString("settings.accessibility.missing", value: "Not granted — auto-paste is disabled until permission is given in System Settings → Privacy & Security → Accessibility.", comment: "Settings label") }
    static var settingsAccessibilityOpen: String { NSLocalizedString("settings.accessibility.open", value: "Open System Settings", comment: "Settings button") }
    static var settingsLanguageRestartHint: String { NSLocalizedString("settings.language.restartHint", value: "Language change takes effect after the next app restart.", comment: "Settings hint") }

    static var aboutVersion: String { NSLocalizedString("about.version", value: "Version", comment: "About label") }
    static var aboutGithub: String { NSLocalizedString("about.github", value: "GitHub Repository", comment: "About label") }
    static var aboutUnquarantineHint: String { NSLocalizedString("about.unquarantine", value: "If macOS refuses to open the app, run:\n`xattr -dr com.apple.quarantine /Applications/TomsClippyLight.app`", comment: "About label") }

    static var popoverSearchPlaceholder: String { NSLocalizedString("popover.search", value: "Search history…", comment: "Popover placeholder") }
    static var popoverPinnedSection: String { NSLocalizedString("popover.section.pinned", value: "Pinned", comment: "Popover section") }
    static var popoverRecentSection: String { NSLocalizedString("popover.section.recent", value: "Recent", comment: "Popover section") }
    static var popoverEmpty: String { NSLocalizedString("popover.empty", value: "No clipboard history yet.\nCopy something to get started.", comment: "Popover empty state") }
    static var popoverActionPin: String { NSLocalizedString("popover.action.pin", value: "Pin", comment: "Popover action") }
    static var popoverActionUnpin: String { NSLocalizedString("popover.action.unpin", value: "Unpin", comment: "Popover action") }
    static var popoverActionDelete: String { NSLocalizedString("popover.action.delete", value: "Delete", comment: "Popover action") }
}
