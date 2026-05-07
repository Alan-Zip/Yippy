//
//  LaunchAtLoginService.swift
//  Yippy
//
//  Created by OpenAI Codex on 4/30/26.
//

import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    @discardableResult
    static func setEnabled(_ isEnabled: Bool) -> Bool {
        do {
            if isEnabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else if SMAppService.mainApp.status != .notRegistered {
                try SMAppService.mainApp.unregister()
            }
            return true
        } catch {
            YippyError(
                localizedDescription: "Failed to \(isEnabled ? "enable" : "disable") launch at login: \(error.localizedDescription)"
            ).log(with: ErrorLogger.general)
            return false
        }
    }
}
