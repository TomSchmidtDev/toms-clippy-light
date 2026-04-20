import SwiftUI

@main
struct TomsClippyLightApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Settings window is managed by AppDelegate.openSettings() via NSWindowController
        // because LSUIElement apps can't reliably use NSApp.sendAction("showSettingsWindow:").
        Settings { EmptyView() }
    }
}
