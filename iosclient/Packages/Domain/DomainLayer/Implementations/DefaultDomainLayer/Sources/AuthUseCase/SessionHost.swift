import Foundation
internal import DefaultLogoutUseCaseImplementation
import UIKit

actor SessionHost {
    private let userDefaults: UserDefaults
    private let dataVersionLabel: String
    
    init(
        userDefaults: UserDefaults,
        dataVersionLabel: String
    ) {
        self.userDefaults = userDefaults
        self.dataVersionLabel = dataVersionLabel
    }
    
    private var activeSessionKey: String {
        "verni_active_session_\(dataVersionLabel)"
    }
    
    private var deviceIdKey: String {
        "verni_device_id_\(dataVersionLabel)"
    }
    
    var activeSession: String? {
        get {
            userDefaults.string(forKey: activeSessionKey)
        }
        set {
            userDefaults.set(newValue, forKey: activeSessionKey)
        }
    }
    
    var deviceId: String {
        get async {
            guard let deviceId = userDefaults.string(forKey: deviceIdKey) else {
                let deviceId = UUID().uuidString
                userDefaults.set(deviceId, forKey: deviceIdKey)
                return deviceId
            }
            return deviceId
        }
    }
}

extension SessionHost: LogoutPerformer {
    func performLogout() -> Bool {
        let hasSession = activeSession != nil
        guard hasSession else {
            return false
        }
        activeSession = nil
        return true
    }
}
