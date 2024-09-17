import AsyncExtensions

public enum LogoutReason: Sendable {
    case refreshTokenFailed
}

public protocol LogoutUseCase: Sendable {
    func logout() async

    var didLogoutPublisher: any AsyncBroadcast<LogoutReason> { get async }
}
