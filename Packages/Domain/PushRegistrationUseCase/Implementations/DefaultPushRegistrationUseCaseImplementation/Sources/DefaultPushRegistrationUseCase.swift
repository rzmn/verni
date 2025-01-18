import PushRegistrationUseCase
import Api
import UIKit
import Logging

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
        do {
            let response = try await api.registerForPushNotifications(
                .init(
                    body: .json(
                        .init(
                            token: token
                        )
                    )
                )
            )
            switch response {
            case .ok:
                logE { "register for push notifications succeeded" }
            case .unauthorized(let payload):
                logE { "failed to register for push notifications response: \(payload)" }
            case .internalServerError(let payload):
                logE { "failed to register for push notifications response: \(payload)" }
            case .undocumented(statusCode: let statusCode, let body):
                logE { "failed to register for push notifications, undocumented response: \(body) code: \(statusCode)" }
            }
        } catch {
            logE { "failed to register for push notifications error: \(error)" }
        }
        
    }
}

extension DefaultPushRegistrationUseCase: Loggable {}
