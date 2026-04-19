import Foundation
@testable import TomsClippyLight

final class FakeLaunchAtLoginService: LaunchAtLoginService, @unchecked Sendable {
    private var _enabled: Bool
    var shouldThrowOnSet: Error?
    private(set) var setCalls: [Bool] = []

    init(initial: Bool = false) { self._enabled = initial }

    var isEnabled: Bool { _enabled }

    func setEnabled(_ enabled: Bool) throws {
        setCalls.append(enabled)
        if let err = shouldThrowOnSet { throw err }
        _enabled = enabled
    }
}
