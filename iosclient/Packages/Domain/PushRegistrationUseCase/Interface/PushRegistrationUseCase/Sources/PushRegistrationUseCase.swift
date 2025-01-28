import Foundation

public protocol PushRegistrationUseCase: Sendable {
    func askForPushToken() async
    func registerForPush(token tokenData: Data) async
}
