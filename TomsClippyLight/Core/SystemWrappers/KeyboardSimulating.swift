import ApplicationServices
import CoreGraphics
import Foundation

public protocol KeyboardSimulating: AnyObject, Sendable {
    func postCommandV()
    func postReturn()
    var isAccessibilityTrusted: Bool { get }
    func requestAccessibilityTrust() -> Bool
}

public final class SystemKeyboardSimulator: KeyboardSimulating, @unchecked Sendable {
    private static let vKeyCode: CGKeyCode      = 0x09
    private static let returnKeyCode: CGKeyCode = 0x24

    public init() {}

    public var isAccessibilityTrusted: Bool {
        AXIsProcessTrusted()
    }

    public func requestAccessibilityTrust() -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        let options = [key: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public func postCommandV() {
        postKey(Self.vKeyCode, flags: .maskCommand)
    }

    /// Posts a bare Return key event (no modifier flags).
    /// Used to re-enter Finder's inline rename mode after focus was stolen.
    public func postReturn() {
        postKey(Self.returnKeyCode, flags: [])
    }

    private func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyDown?.post(tap: .cgSessionEventTap)
        keyUp?.post(tap: .cgSessionEventTap)
    }
}
