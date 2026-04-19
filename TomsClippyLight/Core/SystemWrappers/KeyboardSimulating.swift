import ApplicationServices
import CoreGraphics
import Foundation

public protocol KeyboardSimulating: AnyObject, Sendable {
    func postCommandV()
    var isAccessibilityTrusted: Bool { get }
    func requestAccessibilityTrust() -> Bool
}

public final class SystemKeyboardSimulator: KeyboardSimulating, @unchecked Sendable {
    private static let vKeyCode: CGKeyCode = 0x09

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
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: Self.vKeyCode, keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: Self.vKeyCode, keyDown: false)
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }
}
