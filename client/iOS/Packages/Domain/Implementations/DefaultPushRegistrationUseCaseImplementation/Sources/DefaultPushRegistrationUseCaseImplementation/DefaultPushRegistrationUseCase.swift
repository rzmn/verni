import Domain
import Api
import UIKit
import Logging

public class DefaultPushRegistrationUseCase {
    private let api: ApiProtocol
    public let logger: Logger

    public init(api: ApiProtocol, logger: Logger) {
        self.api = api
        self.logger = logger
    }
}

extension DefaultPushRegistrationUseCase: PushRegistrationUseCase {
    public func askForPushToken() {
        Task.detached { @MainActor in
            self.doAskForPushToken()
        }
    }

    @MainActor func doAskForPushToken() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                Task.detached { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                self.logI { "permission for push notifications denied" }
            }
        }
    }

    public func registerForPush(token tokenData: Data) async {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        let method = Auth.RegisterForPushNotifications(token: token)
        try? await api.run(method: method)
    }
}

extension DefaultPushRegistrationUseCase: Loggable {}
