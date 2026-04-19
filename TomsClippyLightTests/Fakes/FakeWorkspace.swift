import Foundation
@testable import TomsClippyLight

final class FakeWorkspace: WorkspaceProtocol, @unchecked Sendable {
    var frontmostAppBundleID: String?
    var frontmostAppProcessID: pid_t?
    var activateBundleShouldSucceed = true
    var activateProcessShouldSucceed = true

    private(set) var activatedBundleIDs: [String] = []
    private(set) var activatedProcessIDs: [pid_t] = []

    init(bundleID: String? = "com.test.prev", pid: pid_t? = 1234) {
        self.frontmostAppBundleID = bundleID
        self.frontmostAppProcessID = pid
    }

    func activateApp(withBundleID bundleID: String) -> Bool {
        activatedBundleIDs.append(bundleID)
        return activateBundleShouldSucceed
    }

    func activateApp(withProcessID pid: pid_t) -> Bool {
        activatedProcessIDs.append(pid)
        return activateProcessShouldSucceed
    }
}
