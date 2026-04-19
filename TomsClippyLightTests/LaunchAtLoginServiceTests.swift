import Foundation
import Testing
@testable import TomsClippyLight

@Suite("LaunchAtLoginService (Fake)")
struct LaunchAtLoginServiceTests {
    @Test("setEnabled(true) toggles isEnabled")
    func enable() throws {
        let service = FakeLaunchAtLoginService(initial: false)
        try service.setEnabled(true)
        #expect(service.isEnabled)
        #expect(service.setCalls == [true])
    }

    @Test("setEnabled(false) disables")
    func disable() throws {
        let service = FakeLaunchAtLoginService(initial: true)
        try service.setEnabled(false)
        #expect(service.isEnabled == false)
    }

    @Test("setEnabled propagates errors")
    func error() {
        struct SomeError: Error {}
        let service = FakeLaunchAtLoginService(initial: false)
        service.shouldThrowOnSet = SomeError()
        #expect(throws: SomeError.self) {
            try service.setEnabled(true)
        }
    }
}
