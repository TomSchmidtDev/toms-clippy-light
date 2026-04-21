import Foundation
@testable import TomsClippyLight

final class FakeKeyboardSimulator: KeyboardSimulating, @unchecked Sendable {
    var isAccessibilityTrusted: Bool = true
    private(set) var postCommandVCount: Int = 0
    private(set) var postReturnCount: Int = 0
    private(set) var trustRequestCount: Int = 0

    func postCommandV() { postCommandVCount += 1 }
    func postReturn()   { postReturnCount   += 1 }
    func requestAccessibilityTrust() -> Bool {
        trustRequestCount += 1
        return isAccessibilityTrusted
    }
}
