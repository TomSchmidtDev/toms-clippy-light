import SwiftUI

@main
struct TomsClippyLightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(appDelegate.preferences)
                .environment(appDelegate.historyStore)
        }
    }
}
