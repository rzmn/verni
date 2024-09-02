import Domain
import Api
import UIKit
import Logging

public actor DefaultPushRegistrationUseCase {
    private let api: ApiProtocol
    public let logger: Logger

    public init(api: ApiProtocol, logger: Logger) {
        self.api = api
        self.logger = logger
    }
}

extension DefaultPushRegistrationUseCase: PushRegistrationUseCase {
    public func askForPushToken() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization()
            if granted {
                Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                logI { "permission for push notifications denied" }
            }
        } catch {
            logI { "permission for push notifications failed error: \(error)" }
        }
    }

    public func registerForPush(token tokenData: Data) async {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        let method = Auth.RegisterForPushNotifications(token: token)
        try? await api.run(method: method)
    }
}

extension DefaultPushRegistrationUseCase: Loggable {}
