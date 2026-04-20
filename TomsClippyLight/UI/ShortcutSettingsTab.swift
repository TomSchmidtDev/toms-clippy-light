import AppKit
import ApplicationServices
import KeyboardShortcuts
import SwiftUI

struct ShortcutSettingsTab: View {
    @State private var isAccessibilityTrusted: Bool = AXIsProcessTrusted()
    @State private var pollTimer: Timer?

    var body: some View {
        Form {
            Section {
                HStack {
                    Text(L10n.settingsShortcutLabel)
                    Spacer()
                    KeyboardShortcuts.Recorder(for: .showHistory)
                }
            }

            Section(header: Text(L10n.settingsAccessibilityTitle)) {
                if isAccessibilityTrusted {
                    Label(L10n.settingsAccessibilityOk, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text(L10n.settingsAccessibilityMissing)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button(L10n.settingsAccessibilityRequest) {
                            requestAccessibility()
                        }
                        Button(L10n.settingsAccessibilityOpen) {
                            openAccessibilitySettings()
                        }
                    }
                    Text(L10n.settingsAccessibilityRebuildHint)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            startPolling()
        }
        .onDisappear {
            pollTimer?.invalidate()
            pollTimer = nil
        }
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                isAccessibilityTrusted = AXIsProcessTrusted()
            }
        }
    }

    private func requestAccessibility() {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
