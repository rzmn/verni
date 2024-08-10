import Foundation

public protocol PushRegistrationUseCase {
    func registerForPush(token: String) async
}
