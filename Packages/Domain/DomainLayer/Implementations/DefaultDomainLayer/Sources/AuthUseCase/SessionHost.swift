import Foundation
internal import DefaultLogoutUseCaseImplementation
import UIKit

actor SessionHost {
    private var userDefaults: UserDefaults {
        .standard
    }
    
    private var activeSessionKey: String {
        "verni_active_session"
    }
    
    private var deviceIdKey: String {
        "verni_active_session"
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
                let deviceId = (await UIDevice.current.identifierForVendor ?? UUID()).uuidString
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
