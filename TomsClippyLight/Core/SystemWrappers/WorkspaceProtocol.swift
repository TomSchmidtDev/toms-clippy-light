import AppKit
import Foundation

public protocol WorkspaceProtocol: AnyObject, Sendable {
    var frontmostAppBundleID: String? { get }
    var frontmostAppProcessID: pid_t? { get }
    func activateApp(withBundleID bundleID: String) -> Bool
    func activateApp(withProcessID pid: pid_t) -> Bool
}

public final class SystemWorkspace: WorkspaceProtocol, @unchecked Sendable {
    public init() {}

    public var frontmostAppBundleID: String? {
        NSWorkspace.shared.frontmostApplication?.bundleIdentifier
    }

    public var frontmostAppProcessID: pid_t? {
        NSWorkspace.shared.frontmostApplication?.processIdentifier
    }

    public func activateApp(withBundleID bundleID: String) -> Bool {
        guard let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID }) else {
            return false
        }
        return app.activate(from: NSRunningApplication.current)
    }

    public func activateApp(withProcessID pid: pid_t) -> Bool {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return false }
        return app.activate(from: NSRunningApplication.current)
    }
}
