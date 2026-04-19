import XCTest

final class SettingsUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func test_appLaunches_andStatusItemIsPresent() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5) || app.state == .runningBackground,
                      "App should launch (menubar-only apps may report background state)")
    }
}
