import Foundation

public protocol PushRegistrationUseCase {
    func askForPushToken()
    func registerForPush(token tokenData: Data) async
}
