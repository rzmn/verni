import PushRegistrationUseCase
import Api
import UIKit
import Logging
internal import EntitiesApiConvenience

public actor DefaultPushRegistrationUseCase {
    private let api: APIProtocol
    public let logger: Logger

    public init(api: APIProtocol, logger: Logger) {
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
        let response: Operations.RegisterForPushNotifications.Output
        do {
            response = try await api.registerForPushNotifications(
                .init(
                    body: .json(
                        .init(
                            token: token
                        )
                    )
                )
            )
        } catch {
            return logE { "failed to register for push notifications network error: \(error)" }
        }
        do {
            try response.get()
        } catch {
            return logE { "failed to register for push notifications error: \(error)" }
        }
    }
    
    public func unregister() async {
        // TODO: 
    }
}

extension DefaultPushRegistrationUseCase: Loggable {}
