import Foundation
import ServiceManagement

public protocol LaunchAtLoginService: AnyObject, Sendable {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

public final class SystemLaunchAtLoginService: LaunchAtLoginService, @unchecked Sendable {
    public init() {}

    public var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    public func setEnabled(_ enabled: Bool) throws {
        if enabled {
            if SMAppService.mainApp.status == .enabled { return }
            try SMAppService.mainApp.register()
        } else {
            if SMAppService.mainApp.status != .enabled { return }
            try SMAppService.mainApp.unregister()
        }
    }
}
